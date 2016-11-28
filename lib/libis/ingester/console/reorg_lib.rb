require_relative 'menu'
require 'libis/tools/checksum'

@unattended = false

def get_config(config)
  unless @unattended || config
    puts
    puts 'You can supply a configuration name. Configurations are stored in a ${HOME}/.reorg<Config>.data file.'
    puts 'The configuration parameters you set are automatically retrieved and saved under that name.'
    puts 'These configurations exist:'
    puts_config
    config = @hl.ask('Configuration to use.') { |q| q.default = config }
  end
  config
end

def get_base_dir(base_dir)
  unless @unattended && base_dir
    puts
    puts 'First of all supply the path to the directory that needs to be reorganized.'
    base_dir = select_path(true, false, (base_dir || '.'))
  end
  File.absolute_path(base_dir)
end

def get_parse_regex(parse_regex)
  unless @unattended && parse_regex
    puts
    puts 'Now enter a regular expression that needs to be applied to each file in the directory.'
    puts 'Create groups for reference later in the directory structure to be created.'
    parse_regex = @hl.ask('Enter REGEX: ') { |q| q.default = parse_regex }
  end
  Regexp.new(parse_regex)
end

def get_path_expression(path_expression)
  unless @unattended && path_expression
    puts
    puts 'Supply the relative or absolute path for each matching file (including file name).'
    puts 'Use $x for referencing the value of the the x-th group in the regex. "file_name" refers to the original file name.'
    path_expression = @hl.ask('Enter path expression: ') { |q| q.default = path_expression }
  end
  path_expression
end

def get_report_file(report_file)
  if !@unattended || report_file.nil?
    puts
    puts 'Enter a file name for the report. Extension (csv/tsv/xml/yml) specifies the type. Type "-none-" for no report.'
    report_file = @hl.ask('Report file name: ') { |q| q.default = report_file }
  end
  report_file = nil if !report_file || report_file.empty? || report_file == '-none-'
  report_file
end

def get_move_files(move_files)
  if !@unattended || move_files.nil?
    puts
    puts 'Do you want to move the files? If not, a copy operation will be performed and the original files will be left untouched.'
    move_files = @hl.agree('Move files? ', true) { |q| q.default = !!move_files }
  end
  !!move_files
end

def open_report(report_file)
  if report_file
    @report_type = {'.csv' => :csv, '.tsv' => :tsv, '.xml' => :xml, '.yml' => :yml}[File.extname(report_file)]
    unless @report_type
      puts "Unknown file type: #{File.extname(report_file)}"
      exit
    end
    @report = File.open(report_file, 'w+')
  end
end

def for_tsv(string)
  ; string =~ /\t\n/ ? "\"#{string.gsub('"', '""')}\"" : string;
end

def for_csv(string)
  ; string =~ /,\n/ ? "\"#{string.gsub('"', '""')}\"" : string;
end

def for_xml(string, type = :attr)
  ; string.encode(xml: type);
end

def for_yml(string)
  ; string.inspect.to_yaml;
end

def write_report(old_name, new_folder, new_name, remark = nil)
  return unless @report
  case @report_type
    when :tsv
      @report.puts "old_name\tnew_folder\tnew_name\tremark" if @report.size == 0
      @report.puts "#{for_tsv(old_name)}\t#{for_tsv(new_folder)}" +
                       "\t#{for_tsv(new_name)}\t#{for_tsv(remark)}"
    when :csv
      @report.puts 'old_name,new_folder,new_name' if @report.size == 0
      @report.puts "#{for_csv(old_name)},#{for_csv(new_folder)}" +
                       ",#{for_csv(new_name)},#{for_csv(remark)}"
    when :xml
      @report.puts '<?xml version="1.0" encoding="UTF-8"?>' if @report.size == 0
      @report.puts '<report>' if @report.size == 1
      @report.puts '  <file>'
      @report.puts "    <old_name>#{for_xml(old_name, :text)}</old_name>"
      @report.puts "    <new_folder>#{for_xml(new_folder, :text)}</new_folder>"
      @report.puts "    <new_name>#{for_xml(new_name, :text)}</new_name>"
      @report.puts "    <remark>#{for_xml(remark, :text)}</remark>" if remark
      @report.puts '  </file>'
    when :yml
      @report.puts '# Reorganisation report' if @report.size == 0
      @report.puts "- old_name: #{for_yml(old_name)}" +
                       "\n  new_folder: #{for_yml(new_folder)}" +
                       "\n  new_name: #{for_yml(new_name)}" +
                       (remark ? "\n  remark: #{for_yml(remark)}" : '')
    else
      #nothing
  end
end

def close_report
  return unless @report
  if @report_type == :xml
    @report.puts '</report>'
  end
  @report.close
end

def get_dummy_operation(dummy_operation)
  if !@unattended || dummy_operation.nil?
    dummy_operation = !@hl.agree('Perform physical operation on the files?', true)
  end
  dummy_operation
end

def config_file(config)
  File.join(ENV['HOME'], ".reorg#{config}.data")
end

def configurations
  Dir.glob(File.join(ENV['HOME'], '.reorg*.data')).map { |x| x.scan(/reorg(.*).data$/).first.first rescue '' }
end

def save_config(base_dir, parse_regex, path_expression, report_file, move_files, config)
  File.open(config_file(config), 'w') do |f|
    f.puts "dir: #{base_dir}"
    f.puts "regex: #{parse_regex}"
    f.puts "expr: #{path_expression}"
    f.puts "report: #{report_file}"
    f.puts "move: #{move_files ? 'true' : 'false'}"
  end
end

def read_config(config)
  result = {}
  File.open(config_file(config), 'r') do |f|
    f.readlines.each do |l|
      v = l.strip.split(': ')
      result[v.first.to_sym] = v.last if v.last
    end
  end rescue nil
  result[:move] = result[:move] == 'true'
  result
end

def puts_config
  configurations.each do |c|
    x = read_config(c)
    puts "- #{c}:"
    x.each { |k, v| puts "   - #{k}: #{v}" }
  end
end

def compare_entry(src, tgt)
  hasher = Libis::Tools::Checksum.new(:SHA256)
  hasher.digest(src) == hasher.digest(tgt)
end
