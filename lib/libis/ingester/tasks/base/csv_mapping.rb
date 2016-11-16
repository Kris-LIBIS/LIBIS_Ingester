require 'libis/workflow'
require 'roo'
require 'roo-xls'
require 'libis/tools/spreadsheet'

module Libis
  module Ingester
    module CsvMapping

      def load_mapping(options = {})
        file, sheet = options[:file].split('|')
        format = options[:format] || 'csv'
        options[:value] = [options[:value]] unless options[:value].is_a?(Array)
        options[:flag] = [options[:flag]] unless options[:flag].is_a?(Array)
        raise Libis::WorkflowError, 'Mapping file name is empty' if file.blank?
        unless File.exist?(file) && File.readable?(file)
          raise Libis::WorkflowError, "Cannot open mapping file '#{file}'"
        end
        case format
          when 'xls'
            load_xls(file, sheet, options)
          when 'csv'
            load_csv(file, options)
          when 'tsv'
            load_tsv(file, options)
          else
            raise Libis::WorkflowError, "Unsupported mapping format: #{format}"
        end
      end

      private

      def load_tsv(file, options)
        load_csv_or_tsv("\t", file, options)
      end

      def load_csv(file, options)
        load_csv_or_tsv(',', file, options)
      end

      def load_csv_or_tsv(col_sep, file, options)
        result = {
            mapping: {},
            flagged: [],
            errors: []
        }
        csv = Libis::Tools::Csv.open(file, col_sep: col_sep, required: options[:headers], optional: options[:optional_headers] || [])
        csv.each_with_index do |row, i|
          key = row[options[:key]]
          values = options[:value].split('|')
          value = case values.size
                    when 1
                      row[values[0]]
                    when 0
                      nil
                    else
                      values.inject({}) { |v, h| h[v] = row[v]; h }
                  end
          next if options[:ignore_empty_value] && value.blank?
          if key.blank?
            result[:errors] << "Emtpy #{options[:key]} column in row #{i+1} : #{row.to_hash}"
            raise Libis::WorkflowError, result[:errors].last unless options[:collect_errors]
          end
          if value.blank?
            result[:errors] << "Emtpy #{options[:value]} column in row #{i+1} : #{row.to_hash}"
            raise Libis::WorkflowError, result[:errors].last unless options[:collect_errors]
          end
          result[:mapping][key] = value
          result[:flagged] << key if options[:flag] && !row[options[:flag]].blank?
        end
      rescue CSV::MalformedCSVError
        result[:errors] << "Error parsing mapping file #{file}"
        raise Libis::WorkflowError, result[:errors].last unless options[:collect_errors]
      ensure
        csv.close rescue nil
        result
      end

      def load_xls(file, sheet, options)
        result = {
            mapping: {},
            flagged: [],
            errors: []
        }
        key_field = options[:key]
        value_fields = options[:value]
        flag_fields = options[:flag].split('|')
        ignore_empty_value = options[:ignore_empty_value]

        xls = Libis::Tools::Spreadsheet.new(
            "#{file}|#{sheet}",
            required: {key: options[:key]}.merge(Hash[options[:value].map {|v| [v] * 2}])
        )

        xls.each do |h|
          result[:mapping][h[:key]] = options[:value].size == 1 ? h[options[:value].first] : h.select { |k,_| k != :key }
          result
        end

      rescue Exception => e
        result[:errors] << "Error parsing spreadsheet file '#{file}': #{e.message}"
        raise Libis::WorkflowError, result[:errors].last unless options[:collect_errors]

      ensure
        result
      end

=begin
        col_sep = case format
                    when 'tsv'
                      "\t"
                    when 'csv'
                      ','
                    when 'xls'
                      ''
                    else
                      raise Libis::WorkflowError, "Unsupported mapping format: #{format}"
                  end
        begin
          csv = Libis::Tools::Csv.open(file, col_sep: col_sep, required: options[:headers], optional: options[:optional_headers] || [])
          csv.each_with_index do |row, i|
            key = row[key_field]
            value = row[value_field]
            next if ignore_empty_value && value.blank?
            if key.blank?
              result[:errors] << "Emtpy #{key_field} column in row #{i+1} : #{row.to_hash}"
              raise Libis::WorkflowError, result[:errors].last unless options[:collect_errors]
            end
            if value.blank?
              result[:errors] << "Emtpy #{value_field} column in row #{i+1} : #{row.to_hash}"
              raise Libis::WorkflowError, result[:errors].last unless options[:collect_errors]
            end
            result[:mapping][key] = value
            result[:flagged] << key if flag_field && !row[flag_field].blank?
          end
        rescue CSV::MalformedCSVError
          result[:errors] << "Error parsing mapping file #{file}"
          raise Libis::WorkflowError, result[:errors].last unless options[:collect_errors]
        ensure
          csv.close rescue nil
        end

        result

      end
=end

    end
  end
end
