require 'libis/workflow'
require 'libis/tools/spreadsheet'
require 'set'

module Libis
  module Ingester
    module CsvMapping

      XLS_KEYS = [:required, :optional, :extension, :encoding, :col_sep, :quote_char]

      # Open and parse a mapping file.
      #
      # This method relies heavily on the ::Libis::Tools::Spreadsheet class. It will read any CSV, TSV or Excel file and
      # return a mapping table based on the options given. Optionally it can check for 'flags'. A flag is a column that
      # can contain any value and the result will be a list of entries that have a value in that column.
      #
      # All configuration parameters are supplied via a options Hash. The options Hash supports the following keys:
      # - :file : file name (required).
      # - :sheet : sheet name (optional). Only used for spreadsheet formats, not for CSV or TSV. If omitted the first
      #     sheet will be used
      # - :key : the name of the key lookup column (required).
      # - :values : a list of value columns (required).
      # - :flags : a list of flag columns (optional).
      # - :required : a list of columns that must have a value (optional).
      # - :collect_errors : return errors in result instead of raising an exception (optional). If present and evaluates
      #     as 'true', the routine will collect error messages as it parses the file and returns them in the result.
      #     Otherwise the method will throw a ::Libis::WorkflowError on the first error.
      #
      # The following option keys are passed on to the Spreadsheet class:
      # - :extension : :csv, :xlsx, :xlsm, :ods, :xls, :google to help the library in deciding what format the file is in.
      # - :encoding : the encoding of the CSV file. e.g. 'windows-1252:UTF-8' to convert the input from windows code page
      #     1252 to UTF-8 during file reading.
      # - :col_sep : column separator. Default is ',', but can be set to "\t" for TSV files.
      # - :quote_char : character used as string delimiter. Default is the double-quote character ('"').
      #
      # The method will return a Hash with the following keys:
      # - :mapping : a Hash with the designated key values as keys and another Hash as value. For each value in the
      #     options :values list a key-value pair will be present if the value is not empty.
      # - :flagged : a Hash with a list for each flag column listed in options :flags. Each list contains the key values
      #     of the rows that have a non-empty value in the flag column.
      # - :errors : list of error messages (see :collect_errors option flag above).
      #
      # Note: files without headers are supported, but the file's columns will be interpreted in the order that the
      # header values are supplied: first the :key column, then the :values column, then the :flags columns.
      #
      # @param [Hash] options
      # @return [Hash] result structure
      def load_mapping(options = {})
        result = {
            mapping: {},
            flagged: options[:flags].nil? ? {} : options[:flags].inject({}) { |hash, flag| hash[flag] = []; hash },
            errors: []
        }

        # check required options
        [:file, :key, :values].each do |key|
          result[:errors] << "Missing #{key} option in CSV Mapper"
          raise Libis::WorkflowError, result[:errors].last unless options[:collect_errors]
        end
        return result unless result[:errors].empty?

        # check if file can be read
        file = options[:file]
        if file.blank?
          result[:errors] << 'Mapping file name is empty'
          raise Libis::WorkflowError, result[:errors].last unless options[:collect_errors]
          return result
        end
        unless File.exist?(file) && File.readable?(file)
          result[:errors] << "Cannot open mapping file '#{file}'"
          raise Libis::WorkflowError, result[:errors].last unless options[:collect_errors]
          return result
        end

        # options setup
        required = Set[*(options[:key] + (options[:required] || []))]
        options[:required] = required.to_a
        options[:optional] = (Set[*(options[:values] + options[:flags])] - required).to_a

        # open spreadsheet
        file += '|' + options[:sheet] if options[:sheet]
        begin
          xls = Libis::Tools::Spreadsheet.new(file, options.select { |k, _| XLS_KEYS.include?(k) })
        rescue Exception => e
          result[:errors] << "Error parsing spreadsheet file '#{file}': #{e.message}"
          raise Libis::WorkflowError, result[:errors].last unless options[:collect_errors]
        end

        # iterate over content
        xls.each do |row|
          key = row[options[:key]]
          next if key.blank?
          options[:required].each do |c|
            if row[c].blank?
              result[:errors] << "Emtpy #{c} column for key #{key} : #{row}"
              raise Libis::WorkflowError, result[:errors].last unless options[:collect_errors]
            end
          end
          result[:mapping][key] = row.select { |k, _| k != :key }
          options[:flag].each { |flag| result[:flagged][flag] << key unless row[flag].blank? }
        end

        result
      end

    end
  end
end
