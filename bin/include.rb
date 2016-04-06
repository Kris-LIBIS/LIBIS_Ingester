$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
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

def option_menu(title, items, parent_name = nil)
  # if items.empty?
  #   puts "No more #{title}s found."
  #   return false
  # end
  return true if @options[title.downcase.to_sym]
  if (name = @options["#{title.downcase}_name".to_sym])
    item = items.find_by(name: name)
    if item
      @options[title.downcase.to_sym] = item
      return true
    end
  end
  @hl.choose do |menu|
    menu.prompt = "#{title} number: "
    menu.header = "\n#{title.upcase}#{parent_name ? ' for ' + parent_name : ''}"
    menu.select_by = :index_or_name
    items.each do |i|
      menu.choice("#{i.name} (id: #{i.id}) #{yield i if block_given?}") { @options[title.downcase.to_sym] = i }
    end
    menu.choice('--RETURN--') { @options[title.downcase.to_sym] = nil }
  end
  !!@options[title.downcase.to_sym]
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

def get_initializer
  @initializer = ::Libis::Ingester::Initializer.new(@options[:config] || 'site.config.yml')
end

def get_user

  return false unless option_menu('User', Libis::Ingester::User.all)

  loop do
    @options[:password] = @hl.ask('Password: ') { |q| q.echo = '.' } unless @options[:password]
    return true if @options[:user].authenticate(@options[:password])
    @options[:password] = nil
  end

end

def get_org

  return false unless get_user

  # noinspection RubyResolve
  option_menu('Organization', @options[:user].organizations, @options[:user].name)
end

def get_job

  return false unless get_org

  # noinspection RubyResolve
  option_menu('Job', @options[:organization].jobs, @options[:organization].name)
end

def get_run
  return unless get_job

  # noinspection RubyResolve
  option_menu('Run', @options[:job].runs, @options[:job].name) do |run|
    run.status_label
  end
end
