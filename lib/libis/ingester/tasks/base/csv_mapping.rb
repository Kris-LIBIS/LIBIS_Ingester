require 'libis/workflow'
require 'libis/tools/csv'

module Libis
  module Ingester
    module CsvMapping

      def load_mapping(options = {})
        file = options[:file]
        format = options[:format] || 'csv'
        key_field = options[:key]
        value_field = options[:value]
        flag_field = options[:flag]
        ignore_empty_value = options[:ignore_empty_value]
        result = {
            mapping: {},
            flagged: [],
            errors: []
        }
        return result if file.blank?
        unless File.exist?(file) && File.readable?(file)
          raise Libis::WorkflowError, "Cannot open mapping file '#{file}'"
        end
        col_sep = case format
                    when 'tsv'
                      "\t"
                    when 'csv'
                      ','
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

    end
  end
end
