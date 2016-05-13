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

def select_path(dir = true, file = true)
  old_completer = Readline.completion_proc
  old_append_character = Readline.completion_append_character
  puts 'Enter path. <TAB> to complete. Double <TAB> to see list.'
  prompt = "#{File.absolute_path('.')} > "
  Readline.completion_append_character = ''
  Readline.completion_proc = Proc.new do |str|
    list = Dir[str+'*'].grep(/^#{Regexp.escape(str)}/).map { |d| File.directory?(d) ? d + '/' : d }
    list.reject! { |f| File.file?(f) } unless file
    list.reject! { |d| File.directory?(d) } unless dir
    list
  end
  Readline.readline(prompt, true)
ensure
  Readline.completion_proc = old_completer
  Readline.completion_append_character = old_append_character
end
