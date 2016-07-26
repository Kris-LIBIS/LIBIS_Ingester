require 'libis/tools/csv'

module Libis
  module Ingester
    module CsvMapping

      def load_mapping(file, format, headers, key_field, value_field = nil, flag_field = nil, ignore_empty_value = nil)
        result = {
            mapping: {},
            flagged: []
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
                      raise Libis::WorkflowError "Unsupported mapping format: #{format}"
                  end
        begin
          csv = Libis::Tools::Csv.open(file, col_sep: col_sep, required: headers)
          csv.each_with_index do |row, i|
            key = row[key_field]
            value = row[value_field]
            next if ignore_empty_value && value.blank?
            raise Libis::WorkflowError "Emtpy #{key_field} column in row #{i} : #{row.to_hash}" if key.blank?
            raise Libis::WorkflowError "Emtpy #{value_field} column in row #{i} : #{row.to_hash}" if value.blank?
            result[:mapping][key] = value
            result[:flagged] << key if flag_field && !row[flag_field].blank?
          end
        rescue CSV::MalformedCSVError
          raise Libis::WorkflowError "Error parsing mapping file #{file}"
        ensure
          csv.close rescue nil
        end

        result

      end

    end
  end
end
