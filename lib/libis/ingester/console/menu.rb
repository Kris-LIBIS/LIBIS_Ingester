require 'optparse'

def base_opts(opts)
  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end

require 'readline'
require 'highline'
@hl = HighLine.new

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

def select_path(dir = true, file = true, base_dir = '.')
  base_dir = File.absolute_path(File.join(base_dir, '..')) until File.exists?(base_dir) && File.directory?(base_dir)
  old_completer = Readline.completion_proc
  old_append_character = Readline.completion_append_character
  puts 'Enter path. <TAB> to complete. Double <TAB> to see list.'
  prompt = "#{base_dir} > "
  Readline.completion_append_character = ''
  Readline.completion_proc = Proc.new do |str|
    Dir[File.join(base_dir, str)+'*']
        .reject { |d| d =~ /\.\.?$/ }
        .reject { |d| !file && File.file?(d) }
        .reject { |d| !dir && File.directory?(d) }
        .map do |d|
      d = File.directory?(d) ? d + '/' : d
      d.gsub(/^#{Regexp.escape(base_dir)}\/?/, '')
    end
  end
  Readline.readline(prompt, true)
ensure
  Readline.completion_proc = old_completer
  Readline.completion_append_character = old_append_character
end
