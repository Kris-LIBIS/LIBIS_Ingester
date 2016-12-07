#! /usr/bin/env ruby

require_relative '../lib/libis/ingester/console/menu'
require_relative '../lib/libis/ingester/tasks/base/csv_mapping'
require 'libis/services/alma/sru_service'

require 'set'
require 'awesome_print'

# noinspection RubyExpressionInStringInspection
options = {
    mms_headers: %w'Name MMS',
    mms_headers_combo: %w'Name X MMS',
    label_headers: %w'Name Thumbnail Label Group',
    label_headers_combo: %w'Name X Y Label',
    name_header: 'Name',
    mms_header: 'MMS',
    label_header: 'Label',
    thumbnail_flag: 'Thumbnail',
    ignore_empty_mms: false,
    ignore_empty_label: false,
    file_regex: '^(DIGI_[^_]+_[^_]+)_([0-9]+)\.(tif|TIF)$',
    object_label: '"#{$1}"',
    file_label: '"#{$1}_#{$2}"'
}

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on('-l FILE', '--label_file FILE', 'CSV file with labels') do |v|
    options[:label_file] = v
  end

  opts.on('-m FILE', '--mms_file FILE', 'CSV file with MMS ID\'s') do |v|
    options[:mms_file] = v
  end

  opts.on('-u DIR', '--upload_dir DIR', 'Upload dir') do |v|
    options[:upload_dir] = v
  end

  opts.on('-c', '--combo', 'Label file contains both labels and MMS ID\'s') do
    options[:combo] = true
    options[:ignore_empty_label] = true
    options[:ignore_empty_mms] = true
    options[:label_headers] = options[:label_headers_combo]
    options[:mms_headers] = options[:mms_headers_combo]
  end

  opts.on('--label_headers STRING', "Headers for label CSV (default: '#{options[:label_headers]}')") do |v|
    options[:label_headers] = v.split(',')
  end

  opts.on('--mms_headers STRING', "Headers for MMS CSV (default: '#{options[:mms_headers]}')") do |v|
    options[:mms_headers] = v.split(',')
  end

  opts.on('--label_header STRING', "Header value for the label column (default: '#{options[:label_header]}')") do |v|
    options[:label_header] = v
  end

  opts.on('--mms_header STRING', "Header value for the MMS-ID column (default: '#{options[:mms_header]}')") do |v|
    options[:mms_header] = v
  end

  opts.on('--name_header STRING', "Header value for the name column (default: '#{options[:name_header]}')") do |v|
    options[:name_header] = v
  end

  opts.on('--thumb_header STRING', "Header value for the thumbnail flag (default: '#{options[:thumbnail_flag]}')") do |v|
    options[:thumbnail_flag] = v
  end

  opts.on('--file_regex', "Regular expression for file names (default: '#{options[:file_regex]}')") do |v|
    options[:file_regex] = v
  end

  opts.on('--object_name', "Ruby expression for name of object (default: '#{options[:object_label]}')") do |v|
    options[:object_label] = v
  end

  opts.on('--file_name', "Ruby expression for file name column in CSV (default: '#{options[:file_label]}')") do |v|
    options[:file_label] = v
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end

end.parse!

dir = options.delete(:upload_dir)
label_file = options.delete(:label_file)
mms_file = options.delete(:mms_file)
label_file ||= mms_file if options[:combo]

dir ||= begin
  puts 'Upload dir:'
  select_path(true, false, '/nas/upload/ub/digilab')
end

label_file ||= begin
  puts 'CSV file with labels'
  select_path(false, true, '/nas/upload/ub/digilab/tabellen')
end

mms_file = label_file if options[:combo]

mms_file ||= begin
  puts 'CSV file with MMS-ids'
  select_path(false, true, '/nas/upload/ub/digilab/tabellen')
end

puts 'CSV file checker'
puts '================'

puts "Upload dir: #{dir}"
puts "CSV label file: #{label_file}"
puts "CSV MMS file: #{mms_file}"

class CsvChecker
  include Libis::Ingester::CsvMapping

  attr_reader :csv_label_file, :csv_mms_file, :upload_dir, :options, :files, :groups

  def initialize(csv_label, csv_mms, dir, options = {})
    raise RuntimeError, 'No csv file supplied' if csv_label.nil?
    raise RuntimeError, "File not found: #{csv_label}" unless File.exists?(csv_label)
    raise RuntimeError, "File cannot be read #{csv_label}" unless File.readable?(csv_label)
    raise RuntimeError, 'No csv file supplied' if csv_mms.nil?
    raise RuntimeError, "File not found: #{csv_mms}" unless File.exists?(csv_mms)
    raise RuntimeError, "File cannot be read #{csv_mms}" unless File.readable?(csv_mms)
    raise RuntimeError, 'No upload dir supplied' if dir.nil?
    raise RuntimeError, "Dir not found: #{dir}" unless Dir.exists?(dir)
    raise RuntimeError, "Not a dir: #{dir}" unless File.directory?(dir)
    @csv_label_file = csv_label
    @csv_mms_file = csv_mms
    @upload_dir = dir
    @options = options
    read_files
  end

  def check
    errors = check_csv_mms
    errors += check_csv_label
    errors.each { |error| puts error }
    puts 'All checks OK !!!' if errors.empty?
  end

  def check_csv_mms
    alma = Libis::Services::Alma::SruService.new
    opts = {
        file: csv_mms_file,
        keys: [options[:name_header]],
        values: options[:mms_headers],
        collect_errors: false
    }
    opts[:required] = [options[:mms_header]] unless options[:ignore_empty_mms]
    mapping = load_mapping(opts)
    mapping[:mapping].each do |name, map|
      mms = map[options[:mms_header]]
      found = groups.find { |d| d =~ /^#{name}$/ }
      if found
        groups.delete(found)
      else
        mapping[:errors] << "Group '#{name}' referenced in CSV not found."
      end
      begin
        alma.search('alma.mms_id', mms)
      rescue Libis::Services::ServiceError => e
        mapping[:errors] << "Alma service error trying to find Alma MMS ID '#{mms}': #{e.message}"
      end
    end
    groups.each { |dir| mapping[:errors] << "Group '#{dir}' not referenced in CSV." }
    mapping[:errors].dup
  end

  def check_csv_label
    opts = {
        file: csv_label_file,
        keys: [options[:name_header]],
        values: options[:label_headers],
        flags: [options[:thumbnail_flag]],
        collect_errors: false
    }
    opts[:required] = [options[:label_header]] unless options[:ignore_empty_label]
    mapping = load_mapping(opts)
    puts 'Label mapping read:'
    ap mapping
    mapping[:mapping].map do |k, v|
      puts "#{k} : #{v[options[:label_header]]}"
    end
    mapping[:mapping].each do |name, _values|
      files.delete(name) { |_| mapping[:errors] << "File matching '#{name}' not found." }
    end
    files.each { |_, path| mapping[:errors] << "File not referenced in CSV: #{path}" }
    mapping[:errors]
  end

  private

  # @return [Hash] a hash of file names without extension and file paths
  def read_files
    @files = {}
    @groups = Set.new
    Dir.glob(File.join(upload_dir, '**', '*')).select do |path|
      if File.file?(path) && File.basename(path) =~ Regexp.new(options[:file_regex])
        @groups << eval(options[:object_label])
        @files[eval(options[:file_label])] = path
        true
      else
        false
      end
    end
  end

end

CsvChecker.new(label_file, mms_file, dir, options).check
