#!/usr/bin/env ruby
require_relative '../lib/libis/ingester/console/reorg_lib'

######## Command-line
base_dir, parse_regex, path_expression, report_file = read_entries
dummy_operation = nil

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  base_opts(opts)

  opts.on('-b STRING', '--base STRING', 'Directory that needs to be reorganized') do |v|
    base_dir = v
  end

  opts.on('-f REGEX', '--filter REGEX', 'Regex for file name matching') do |v|
    parse_regex = v
  end

  opts.on('-e STRING', '--expression STRING', 'Path expression for new file path') do |v|
    path_expression = v
  end

  opts.on('--report FILE', 'Generate report in FILE') do |v|
    report_file = v
  end

  opts.on('--no-report', 'Do not generate a report') do
    report_file = false
  end

  opts.on('--dummy', 'Do not perform physical actions') do
    dummy_operation = true
  end

  opts.on('--unattended', 'Run without asking for input') do
    @unattended = true
  end

end.parse!

######### Source dir
base_dir = get_base_dir(base_dir)

######### File REGEX
parse_regex = get_parse_regex(parse_regex)

######### Target expression
path_expression = get_path_expression(path_expression)
exit if path_expression.empty?

######### Report
report_file = get_report_file(report_file)

######### Dummy operations
dummy_operation = get_dummy_operation(dummy_operation)

######### Start
puts
puts 'OK. We are all set. Starting to parse the files in the directory.'

puts
puts '========================================================================================='
puts "Directory to reorganize: #{base_dir}"
puts "Regex: #{parse_regex}"
puts "Path expression: #{path_expression}"
puts report_file ? "Creating report file #{report_file}" : 'Not creating a report'
puts (dummy_operation ? 'Not p' : 'P') + 'erforming physical operations'
puts '========================================================================================='
puts
exit unless @unattended || @hl.agree('Last chance to bail out. Continue?')

puts
puts 'This can take a while. Please sit back and relax, grab a cup of coffee, have a quick nap or read a good book ...'

# Save entries
save_entries(base_dir, parse_regex, path_expression, report_file)

# keeps track of folders created
require 'set'
target_dir_list = Set.new

open_report(report_file)

require 'fileutils'
Dir.new(base_dir).entries.each do |file_name|
  next if file_name =~/^\.\.?$/
  entry = File.join(base_dir, file_name)
  unless File.file?(entry)
    puts "Skipping directory #{entry}."
    next
  end
  unless file_name =~ parse_regex
    puts "Skipping file #{file_name}. File name does not match expression."
    next
  end
  target = eval(path_expression)
  target_dir = File.dirname(target)
  unless target_dir_list.member?(target_dir)
    puts "-> Create directory '#{target_dir}'" unless @report
    FileUtils.mkpath(File.join(base_dir, target_dir)) unless dummy_operation
    target_dir_list << target_dir
  end
  puts "-> Move '#{file_name}' to '#{target}'" unless @report
  FileUtils.move(entry, File.join(base_dir, target)) unless dummy_operation
  write_report(entry, File.join(base_dir, target_dir), File.basename(target))
end

close_report

puts
puts 'Done!'
puts
