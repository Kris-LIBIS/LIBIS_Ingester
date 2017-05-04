#!/usr/bin/env ruby
require_relative '../lib/libis/ingester/console/reorg_lib'

require 'filesize'

FILE_OPERATIONS = {
    move: 'moved',
    copy: 'copied',
    link: 'linked'
}

######## Command-line
config = nil
x = read_config('')
base_dir = x[:dir]
parse_regex = x[:regex]
path_expression = x[:expr]
report_file = x[:report]
file_operation = if x.has_key?(:move)
                   x[:move] ? :move : :copy
                 else
                   x[:operation]
                 end
dummy_operation = nil
interactive = false
overwrite = false

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  base_opts(opts)

  opts.on('-c', '--config [STRING]', 'Configuration name') do |v|
    config = v
    x = read_config(v)
    base_dir = x[:dir]
    parse_regex = x[:regex]
    path_expression = x[:expr]
    report_file = x[:report]
    file_operation = if x.has_key?(:move)
                       x[:move] ? :move : :copy
                     else
                       x[:operation]
                     end
    dummy_operation = nil
    interactive = false
    overwrite = false
  end

  opts.on('-i', '--[no-]interactive', 'Ask for action when changed files are found') do |v|
    interactive = v
  end

  opts.on('-o', '--[no-]overwrite', 'Overwrite target if changed') do |v|
    overwrite = v
  end

  opts.on('--file-operation', [:move, :copy, :link], 'Operation to perform on files found') do |v|
    file_operation = v
  end

  opts.on('-b', '--base STRING', String, 'Directory that needs to be reorganized') do |v|
    base_dir = v
  end

  opts.on('-f', '--filter REGEX', Regexp, 'Regex for file name matching') do |v|
    parse_regex = v
  end

  opts.on('-e', '--expression STRING', String, 'Path expression for new file path') do |v|
    path_expression = v
  end

  opts.on('--report FILE', String, 'Generate report in FILE') do |v|
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

######### Configuration
config = get_config(config)

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

######### Move files
file_operation = get_file_operation(file_operation)

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
exit unless @unattended || @hl.agree('Last chance to bail out. Continue?', true)

puts
puts 'This can take a while. Please sit back and relax, grab a cup of coffee, have a quick nap or read a good book ...'

# Save entries
save_config(base_dir, parse_regex, path_expression, report_file, file_operation, config)

# keeps track of folders created
require 'set'
target_dir_list = Set.new

open_report(report_file)

require 'fileutils'
count = {move: 0, duplicate: 0, update: 0, reject: 0, skipped_dir: 0, unmatched_file: 0}

Dir.new(base_dir).entries.each do |file_name|
  next if file_name =~/^\.\.?$/
  entry = File.join(base_dir, file_name)
  unless File.file?(entry)
    puts "Skipping directory #{entry}." unless @report
    write_report(entry, '', '', 'Directory - skipped.')
    count[:skipped_dir] += 1
    next
  end
  unless file_name =~ parse_regex
    puts "Skipping file #{file_name}. File name does not match expression." unless @report
    write_report(entry, '', '', 'Mismatch - skipped.')
    count[:unmatched_file] += 1
    next
  end
  target = eval(path_expression)
  target_file = File.basename(target)
  target_dir = File.dirname(target)
  target_dir = File.join(base_dir, target_dir) unless target_dir[0] == '/'
  unless target_dir_list.include?(target_dir)
    puts "-> Create directory '#{target_dir}'" unless @report
    FileUtils.mkpath(target_dir) unless dummy_operation
    target_dir_list << target_dir
  end
  target_path = File.join(target_dir, target_file)
  remark = nil
  action = false
  if File.exist?(target_path)
    if compare_entry(entry, target_path)
      remark = 'Duplicate - skipped.'
      count[:duplicate] += 1
      $stderr.puts "Duplicate file entry: #{entry}." unless @report
    else
      # puts "source: #{File.mtime(entry)} #{'%11s' % Filesize.new(File.size(entry)).pretty} #{entry}"
      # puts "target: #{File.mtime(target_path)} #{'%11s' % Filesize.new(File.size(target_path)).pretty} #{target_path}"
      if interactive ? @hl.agree('Overwrite target?') {|q| q.default = overwrite} : overwrite
        remark = 'Duplicate - updated'
        action = true
        count[:update] += 1
      else
        remark = 'Duplicate - rejected.'
        $stderr.puts "ERROR: #{entry} exists with different content." unless @report
        count[:reject] += 1
      end
    end
  else
    action = true
    count[:move] += 1
  end
  if action
    puts "-> #{file_operation} '#{file_name}' to '#{target}'" unless @report
    case file_operation
      when :move
        FileUtils.move(entry, File.join(target_dir, target_file), force: true)
      when :copy
        FileUtils.copy(entry, File.join(target_dir, target_file))
      when :link
        FileUtils.symlink(entry, File.join(target_dir, target_file), force: true)
      else
        # Shouldn't happen
        raise RuntimeError, "Bad file operation: '#{file_operation}'"
    end unless dummy_operation
  end
  write_report(entry, target_dir, target_file, remark)
end

$stderr.puts "#{'%8d' % count[:skipped_dir]} dir(s) found and skipped."
$stderr.puts "#{'%8d' % count[:unmatched_file]} file(s) found that did not match and skipped."
$stderr.puts "#{'%8d' % count[:move]} file(s) #{FILE_OPERATIONS[file_operation]}."
$stderr.puts "#{'%8d' % count[:duplicate]} duplicate(s) found and skipped."
$stderr.puts "#{'%8d' % count[:update]} changed file(s) found and updated."
$stderr.puts "#{'%8d' % count[:reject]} changed file(s) found and rejected."

close_report

puts
puts 'Done!'
puts
