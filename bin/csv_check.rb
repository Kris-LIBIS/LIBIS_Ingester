#! /usr/bin/env ruby

require_relative '../lib/libis/ingester/console/menu'
require 'libis/services/alma/sru_service'
require 'libis/tools/csv'
require 'set'

csv_file = ARGV[0]
dir = ARGV[1]

puts 'CSV file checker'
puts '================'

if csv_file
  puts "CSV file: #{csv_file}"
else
  csv_file = select_path(false, true, '/nas/upload/ub/digilab/tabellen')
end

if dir
  puts "Upload dir: #{dir}"
else
  dir = select_path(true, false, '/nas/upload/ub/digilab')
end

class CsvChecker

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
    @options = {
        mms_headers: %w'Name MMS',
        label_headers: %w'Name Label',
        name_header: 'Name',
        mms_header: 'MMS',
        label_header: 'Label',
        file_regex: '^(DIGI_[^_]+_[^_]+)_([0-9]+)\.(tif|TIF)$',
        group_label: '$1',
        file_label: '$1 + "_" + $2'
    }.merge options
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
    csv = open_csv(csv_mms_file, options[:mms_headers])
    errors = []
    csv.each_with_index do |line, i|
      name = line[options[:name_header]]
      mms = line[options[:mms_header]]
      next if options[:ignore_empty_mms] && mms.blank?
      errors << "Emtpy Name column in row #{i} : #{line.to_hash}" if name.blank?
      next if name.blank?
      found = groups.find { |d| d =~ /^#{name}$/ }
      if found
        groups.delete(found)
      else
        errors << "Group '#{name}' referenced in CSV not found."
      end
      if mms.blank?
        errors << "Emtpy MMS column in row #{i} : #{line.to_hash}" if mms.blank?
        next
      end
      begin
        alma.search('alma.mms_id', mms)
      rescue Libis::Services::ServiceError => e
        errors << "Alma service error trying to find Alma MMS ID '#{mms}': #{e.message}"
      end
    end
    csv.close
    groups.each { |dir| errors << "Group '#{dir}' not referenced in CSV." }
    errors
  end

  def check_csv_label
    csv = open_csv(csv_label_file, options[:label_headers])
    errors = []
    csv.each_with_index do |line, i|
      name = line[options[:name_header]]
      label = line[options[:label_header]]
      next if options[:ignore_empty_label] && label.blank?
      errors << "Emtpy Name column in row #{i} : #{line.to_hash}" if name.blank?
      next if name.blank?
      files.delete(name) { |_| errors << "File matching '#{name}' not found." }
      errors << "Emtpy Label column in row #{i} : #{line.to_hash}" if label.blank?
    end
    csv.close
    files.each { |_, path| errors << "File not referenced in CSV: #{path}" }
    errors
  end

  private

  # @return [Hash] a hash of file names without extension and file paths
  def read_files
    @files = {}
    @groups = Set.new
    Dir.glob(File.join(upload_dir, '**', '*')).select do |path|
      if File.file?(path) && File.basename(path) =~ Regexp.new(options[:file_regex])
        @groups << eval(options[:group_label])
        @files[eval(options[:file_label])] = path
        true
      else
        false
      end
    end
  end

  def open_csv(csv_file, header_list)
    Libis::Tools::Csv.open(csv_file, required: header_list)
  end

end

CsvChecker.new(csv_file, csv_file, dir,
               mms_headers: %w'Name X MMS',
               label_headers: %w'Name X Y Label',
               name_header: 'Name',
               mms_header: 'MMS',
               label_header: 'Label',
               ignore_empty_mms: true,
               ignore_empty_label: true,
).check
