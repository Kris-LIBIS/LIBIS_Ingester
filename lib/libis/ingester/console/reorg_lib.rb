require_relative 'menu'

def get_base_dir(base_dir)
  if base_dir
    puts "Directory to reorganize: #{base_dir}"
  else
    puts
    puts 'First of all supply the path to the directory that needs to be reorganized.'
    base_dir = select_path(true, false)
  end
  File.absolute_path(base_dir)
end

def get_parse_regex(parse_regex)
  if parse_regex
    puts "Regex: #{parse_regex}"
  else
    puts
    puts 'Now enter a regular expression that needs to be applied to each file in the directory.'
    puts 'Create groups for reference later in the directory structure to be created.'
    parse_regex = @hl.ask('Enter REGEX: ') { |q| q.readline = true }
  end
  Regexp.new(parse_regex)
end

def get_path_expression(path_expression)
  if path_expression
    puts "Path expression: #{path_expression}"
  else
    puts
    puts 'Supply the relative path for each matching file (including file name).'
    puts 'Use $x for referencing the value of the the x-th group in the regex. "file_name" refers to the original file name.'
    path_expression = @hl.ask('Enter path expression (default: no action): ') { |q| q.readline = true }
  end
  path_expression
end

def open_report(report_file)
  if report_file.nil?
    puts
    puts 'Enter a file name for the report. Extension (csv/tsv/xml/yml) specifies the type.'
    report_file = @hl.ask('Report file name (default: no report): ') { |q| q.readline = true }
  else
    puts report_file ? "Creating report file #{report_file}" : 'Not creating a report'
  end
  report_file = nil if !report_file || report_file.empty?

  if report_file
    @report_type = {'.csv' => :csv, '.tsv' => :tsv, '.xml' => :xml, '.yml' => :yml}[File.extname(report_file)]
    unless @report_type
      puts "Unknown file type: #{File.extname(report_file)}"
      exit
    end
    @report = File.open(report_file, 'w+')
  end
end

def for_tsv(string); string =~ /\t\n/ ? "\"#{string.gsub('"', '""')}\"" : string; end
def for_csv(string); string =~ /,\n/ ? "\"#{string.gsub('"', '""')}\"" : string; end
def for_xml(string, type = :attr); string.encode(xml: type); end
def for_yml(string); string.inspect.to_yaml; end

def write_report(old_name, new_folder, new_name)
  return unless @report
  case @report_type
    when :tsv
      @report.puts "old_name\tnew_folder\tnew_name" if @report.size == 0
      @report.puts "#{for_tsv(old_name)}\t#{for_tsv(new_folder)}" +
                       "\t#{for_tsv(new_name)}"
    when :csv
      @report.puts 'old_name,new_folder,new_name' if @report.size == 0
      @report.puts "#{for_csv(old_name)},#{for_csv(new_folder)}" +
                       ",#{for_csv(new_name)}"
    when :xml
      @report.puts '<?xml version="1.0" encoding="UTF-8"?>' if @report.size == 0
      @report.puts '<report>' if @report.size == 1
      @report.puts '  <file>'
      @report.puts "    <old_name>#{for_xml(old_name, :text)}</old_name>"
      @report.puts "    <new_folder>#{for_xml(new_folder, :text)}</new_folder>"
      @report.puts "    <new_name>#{for_xml(new_name, :text)}</new_name>"
      @report.puts '  </file>'
    when :yml
      @report.puts '# Reorganisation report' if @report.size == 0
      @report.puts "- old_name: #{for_yml(old_name)}" +
                       "\n  new_folder: #{for_yml(new_folder)}" +
                       "\n  new_name: #{for_yml(new_name)}"
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
  if dummy_operation.nil?
    dummy_operation = !@hl.agree('Perform physical operation on the files?')
  else
    puts (dummy_operation ? 'Not p' : 'P') + 'erforming physical operations'
  end
  dummy_operation
end

