$:.unshift File.join(File.dirname(__FILE__), '..', '..', '..')
require 'libis-ingester'
require 'libis-workflow'
require 'libis-workflow-mongoid'
require 'libis-format'
require 'libis-services'
require 'libis-tools'

require 'libis/ingester/initializer'

require 'highline'
@hl = HighLine.new

@options = {}

def db_menu(title, items, options = {}, &block)
  key = title.downcase.to_sym
  return @options[key] if @options[key]
  if (name = @options["#{key}_name".to_sym])
    item = items.find_by(name: name)
    if item
      @options[key] = item
      return item
    end
  end
  options[:proc] = lambda { |item| @options[title.downcase.to_sym] = item }
  block = Proc.new { |item| item.name } unless block_given?
  selection_menu(title, items, options, &block)
end

def selection_menu(title, items, options = {})
  if options[:hidden]
    options[:hidden].merge!('' => Proc.new { nil })
  else
    options[:hidden] = {'' => Proc.new { nil }}
  end
  keys = options[:hidden].keys.map { |key| key == '' ? '<return>' : key }
  prompt = "#{options[:prompt] || "Select #{title}"} (#{keys.join('/')})"
  @hl.choose do |menu|
    menu.index = options[:index] if options[:index]
    menu.prompt = prompt
    menu.header = options[:header] || "\n#{title}#{options[:parent] ? ' for ' + options[:parent] : ''}"
    menu.select_by = :index_or_name
    menu.layout = options[:layout] if options[:layout]
    (options[:prepend] || {}).each { |label, proc| menu.choice(label) { proc.call(label) } }
    items.each do |item|
      menu.choice(block_given? ? yield(item) : item) { options[:proc] ? options[:proc].call(item) : item }
    end
    (options[:append] || {}).each { |label, proc| menu.choice(label) { proc.call(label) } }
    (options[:hidden] || {}).each { |label, proc| menu.hidden(label) { proc.call(label) } }
  end
end

require 'optparse'

def common_opts(opts)
  opts.on('-c', '--config CONFIG', 'Config file') do |v|
    @options[:config] = v
  end
  opts.on('--version', 'Show version information') do
    puts "Libis::Tools ................ #{Libis::Tools::VERSION}"
    puts "Libis::Format ............... #{Libis::Format::VERSION}"
    puts "Libis::Workflow ............. #{Libis::Workflow::VERSION}"
    puts "Libis::Workflow::Mongoid .... #{Libis::Workflow::Mongoid::VERSION}"
    puts "Libis::Services ............. #{Libis::Services::VERSION}"
    puts "Libis::Ingester ............. #{Libis::Ingester::VERSION}"
    exit
  end
  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end

def db_opts(opts)
  opts.on('-d', '--delete', 'Delete all runs') do |v|
    @options[:delete] = v
  end

  opts.on('-r', '--reset', 'Reset the complete database') do |v|
    @options[:reset] = v
  end
end

def user_opts(opts)
  opts.on('-u', '--user USER', 'User name') do |v|
    @options[:user_name] = v
  end
  opts.on('-p', '--password PASSWORD', 'Password') do |v|
    @options[:password] = v
  end
end

def org_opts(opts)
  user_opts(opts)
  opts.on('-o', '--organization NAME', 'Organization name') do |v|
    @options[:organization_name] = v
  end
end

def job_opts(opts)
  org_opts(opts)
  opts.on('-j', '--job NAME', 'Job name') do |v|
    @options[:job_name] = v
  end
end

def run_opts(opts)
  job_opts(opts)
  opts.on('-r', '--run NAME', 'Run name') do |v|
    @options[:run_name] = v
  end

end

def get_sidekiq
  @initializer = ::Libis::Ingester::Initializer.instance
  @initializer.configure(@options[:config] || 'site.config.yml')
  @initializer.sidekiq
end

def get_initializer
  @initializer = ::Libis::Ingester::Initializer.init(@options[:config] || 'site.config.yml')
end

# noinspection RubyResolve
def select_user

  return false unless db_menu('User', Libis::Ingester::User.all) do |user|
    "#{user.name} (#{user.organizations.count} organizations)"
  end

  loop do
    @options[:password] = @hl.ask('Password: ') { |q| q.echo = '.' } unless @options[:password]
    return true if @options[:user].authenticate(@options[:password])
    @options[:password] = nil
  end

end

# noinspection RubyResolve
def select_organization

  return false unless select_user

  # noinspection RubyResolve
  db_menu('Organization', @options[:user].organizations, parent: @options[:user].name) do |org|
    "#{org.name} (#{org.jobs.count} jobs)"
  end
end

def select_job

  return false unless select_organization

  # noinspection RubyResolve
  db_menu('Job', @options[:organization].jobs, parent: @options[:organization].name) do |job|
    "#{job.name} (#{job.runs.count} runs)"
  end
end

def select_run
  return unless select_job

  # noinspection RubyResolve
  db_menu('Run', @options[:job].runs, parent: @options[:job].name) { |run| "#{run.name} - #{run.status_label}" }
end

def get_processes
  processes = []
  ::Sidekiq::ProcessSet.new.each { |process| processes.push(process) }
  processes
end

def select_process(processes = nil, options = {})
  processes ||= get_processes
  format = '%-30s %-30s %s'
  xformat = '   ' + format
  xformat = ' ' + xformat if processes.count > 9
  header = xformat % %w(Process Workers Queues)
  selection_menu('Process', processes, options.merge(header: header)) do |process|
    name = '%s [%d]' % [process['tag'], process['pid']]
    workers = '(%d of %d busy)' % [process['busy'], process['concurrency']]
    workers += ' **HALTED**' if process['quiet'] == 'true'
    format % [
        '%.29s %s' % [name, '.' * [0, 29 - name.size].max],
        '%.29s %s' % [workers, '.' * [0, 29 - workers.size].max],
        process['queues'].join(', ')
    ]
  end
end

def select_active_queue(options = {})
  queues = Set.new
  get_processes.each do |process|
    next if process.stopping?
    process['queues'].each { |queue| queues.add(queue) }
  end
  queuelist = queues.each_with_object([]) { |q, l| l << Sidekiq::Queue.new(q) }
  select_queue(queuelist, options)
end

def select_defined_queue(options = {})
  select_queue(Sidekiq::Queue.all, options)
end

def select_queue(queue_list, options = {})
  process_map = {}
  get_processes.each do |process|
    process['queues'].each do |queue|
      process_map[queue] ||= []
      process_map[queue] << process['tag']
    end
  end

  menu = {}
  menu['+'] = Proc.new {
    name = @hl.ask('queue name:') { |q| q.validate = /\A[a-z][a-z0-9_]*\Z/ }
    Sidekiq::Client.new.redis_pool.with do |conn|
      conn.multi do
        conn.sadd('queues'.freeze, name)
      end
    end
    Sidekiq::Queue.new(name)
  } if options[:with_create]
  menu['-'] = Proc.new do
    queue = select_defined_queue
    queue.clear if queue.is_a?(Sidekiq::Queue)
    true
  end if options[:with_delete]

  format = '%-30s %-20s %s'
  xformat = '   ' + format
  xformat = ' ' + xformat if queue_list.count > 9
  header = xformat % %w(Name Waiting Processes)
  selection_menu('Queue', queue_list, hidden: menu, header: header) do |queue|
    format % [
        '%.29s %s' % [queue.name, '.' * [0, 29 - queue.name.size].max],
        '%d %s' % [queue.size, '.' * [0, 19 - queue.size.to_s.size].max],
        (process_map[queue.name] || []).join(' ')
    ]
  end
end

def select_worker(queue = nil)
  queue ||= select_defined_queue
  return unless queue.is_a?(Sidekiq::Queue)
  workers = []
  queue.each { |worker| workers << worker }
  selection_menu('Worker', workers) do |worker|
    "#{worker.enqueued_at} : #{worker.klass.constantize.subject(worker.args.first).name} #{worker.args.last}"
  end
end

def select_options(job)
  options = {}
  job.workflow.config['input'].each do |key, value|
    options[key] = value['default']
  end
  job.input.each do |key, value|
    options[key] = value
  end
  set_option = Proc.new { |opt|
    key, value = opt
    puts "key: #{key}, value: #{value}"
    options[key] = if value
                     @hl.ask("#{key} : ", value.class) { |q| q.default = value }
                   else
                     @hl.ask("#{key} : ")
                   end
    true
  }

  loop do
    option = selection_menu('Parameters', options, parent: job.name, proc: set_option) { |opt| "#{opt.first} : #{opt.last}" }
    break unless option
  end

  options

end

def select_bulk_option(options)
  option = selection_menu('Bulk parameter', options) { |opt| "#{opt.first} : #{opt.last}" }
  return nil unless option
  maxlevel = @hl.ask('Number of subdir levels to process', Integer) { |q| q.default = 1 }

  dirs = `find #{option.last} -mindepth #{maxlevel} -maxdepth #{maxlevel} -type d -print`.split("\n")
  { key: option.first, values: dirs }
end

def select_item(item)
  selection_menu('item', item.items, header: "Subitems of #{item.name}") {|i| "#{i.class.name.split('::').last}: '#{i.name}' (#{i.items.count} items) [#{i.status_label}]"}
end

