require 'optparse'
require 'set'

def base_opts(opts)
  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end

require 'readline'
require 'highline'
@hl = HighLine.new

require 'yaml'

def get_operator_email
  users = YAML.load_file('data/users.yml')
  @operator_email = @hl.choose do |menu|
    menu.prompt = 'Select user: '
    users.each { |u| menu.choice(u['name']) {u['email']} }
    menu.choice('other') { puts "Add user to 'data/users.yml' file"; exit }
  end
end

def selection_menu(title, items, options = {})
  (options[:hidden] ||= {}).merge!('' => Proc.new {nil})
  keys = options[:hidden].keys.map {|key| key == '' ? '<return>' : key}
  keys << '*' if options[:multiselect]
  prompt = "#{options[:prompt] || "Select #{title}"} (#{keys.join('/')})"
  @hl.choose do |menu|
    menu.index = options[:index] if options[:index]
    menu.prompt = prompt
    menu.header = options[:header] || "\n#{title}#{options[:parent] ? ' for ' + options[:parent] : ''}"
    menu.select_by = :index_or_name
    menu.layout = options[:layout] if options[:layout]
    (options[:prepend] || {}).each {|label, proc| menu.choice(label) {proc.call(label)}}
    items.each do |item|
      menu.choice(block_given? ? yield(item) : item) {options[:proc] ? options[:proc].call(item) : item}
    end
    (options[:append] || {}).each {|label, proc| menu.choice(label) {proc.call(label)}}
    (options[:hidden] || {}).each {|label, proc| menu.hidden(label) {proc.call(label)}}
    if options[:multiselect]
      menu.hidden('*') {
        answer = @hl.ask('Enter a list of numbers and/or ranges: ')
        return true if answer.blank?
        result = Set.new
        answer.split(/\s*[,;\s]\s*/).each do |entry|
          case entry
          when /^\d+\.\.\d+$/
            begin
              range = entry.split('..').map {|d| Integer(d)}
              items[(range[0] - 1)..(range[1] - 1)].each do |item|
                result << item
              end
            rescue => e
              puts "Error - problem interpreting range '#{entry}': #{e.message}"
            end
          when /^\d+$/
            begin
              result << items[entry.to_i - 1]
            rescue => e
              puts "Error - problem interpreting number '#{entry}': #{e.message}"
            end
          else
            puts "Error - malformed entry: '#{entry}'"
          end
        end
        result.reject {|v| v.blank?}
        result.map {|item| options[:proc] ? options[:proc].call(item) : item}
      }
    end
  end
end

def select_path(dir = true, file = true, base_dir)
  base_dir ||= '.'
  base_dir = File.absolute_path(File.join(base_dir, '..')) until File.exists?(base_dir) && File.directory?(base_dir)
  old_completer = Readline.completion_proc
  old_append_character = Readline.completion_append_character
  puts 'Enter path. <TAB> to complete. Double <TAB> to see list.'
  prompt = "#{base_dir} > "
  Readline.completion_append_character = ''
  Readline.completion_proc = Proc.new do |str|
    str = File.join(base_dir, str) unless str =~ /^\//
    Dir[str + '*']
        .reject {|d| d =~ /\.\.?$/}
        .reject {|d| !file && File.file?(d)}
        .reject {|d| !dir && File.directory?(d)}
        .map do |d|
      d = File.directory?(d) ? d + '/' : d
      d.gsub(/^#{Regexp.escape(base_dir)}\/?/, '')
    end
  end
  str = Readline.readline(prompt, true)
  str = File.join(base_dir, str) unless str =~ /^\//
  str
ensure
  Readline.completion_proc = old_completer
  Readline.completion_append_character = old_append_character
end
