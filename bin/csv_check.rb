#! /usr/bin/env ruby

require 'libis/services/alma/sru_service'
require 'libis/tools/csv'

csv_file = ARGV[0]
dir = ARGV[1]

puts 'CSV file checker'
puts '================'

puts "CSV file: #{csv_file}"
puts "Upload dir: #{dir}"

class CsvChecker

  attr_reader :csv_label_file, :csv_mms_file, :upload_dir, :options

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
        label_headers: %w'Name X Label Y',
        name_header: 'Name',
        mms_header: 'MMS',
        label_header: 'Label'
    }.merge options
  end

  def check
    errors = check_csv_mms
    errors += check_csv_label
    errors.each { |error| puts error }
    errors.empty?
  end

  def check_csv_mms
    dirs = dir_list
    alma = Libis::Services::Alma::SruService.new
    csv = open_csv(csv_mms_file, options[:mms_headers])
    errors = []
    csv.each_with_index do |line, i|
      name = line[options[:name_header]]
      errors << "Emtpy Name column in row #{i} : #{line.to_hash}" if name.blank?
      next if name.blank?
      found = dirs.find { |d| d =~ /^#{name}$/ }
      if found
        dirs.delete(found)
      else
        errors << "Dir '#{name}' in CSV does not exist."
      end
      mms = line[options[:mms_header]]
      if !options[:ignore_empty_mms] && mms.blank?
        errors << "Emtpy MMS column in row #{i} : #{line.to_hash}" if mms.blank?
        next
      end
      begin
        alma.search('alma.mms_id', mms)
      rescue Libis::Services::ServiceError => e
        errors << "Alma service error trying to find Alma MMS ID '#{mms}': #{e.message}"
      end
    end
    dirs.each { |dir| errors << "Dir not referenced in CSV: #{dir}" }
    csv.close
    errors
  end

  def check_csv_label
    files = files_list
    csv = open_csv(csv_label_file, options[:label_headers])
    errors = []
    csv.each_with_index do |line, i|
      name = line[options[:name_header]]
      errors << "Emtpy Name column in row #{i} : #{line.to_hash}" if name.blank?
      next if name.blank?
      files.delete(name) { |_| errors << "File '#{name}' in CSV not found." }
      label = line[options[:label_header]]
      errors << "Emtpy Label column in row #{i} : #{line.to_hash}" if label.blank?
    end
    csv.close
    files.each { |file| errors << "File not referenced in CSV: #{file}" }
  end

  private

  # @return [Hash] a hash of file names without extension and file paths
  def files_list
    Dir.glob(File.join(upload_dir, '**', '*')).select do |path|
      File.file?(path)
    end.reduce({}) do |path, hash|
      hash[File.basename(path, '.*')] = path
    end
  end

  def dir_list
    Dir.entries(upload_dir).select do |dir|
      File.directory?(dir) && !dir =~ /^\.{1,2}$/
    end
  end

  def open_csv(csv_file, header_list)
    Libis::Tools::Csv.open(csv_file, required: header_list)
  end

end

CsvChecker.new(csv_file, csv_file, dir).check
