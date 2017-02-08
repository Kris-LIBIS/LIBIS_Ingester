require 'libis/tools/parameter'

require_relative 'csv_mapping'
module Libis
  module Ingester
    module Base

      # noinspection ALL
      module Mapping
        include Libis::Ingester::CsvMapping

        def self.included(klass)
          fail("#{klass.name} should be a ParameterContainer.") unless klass.ancestors.include? Libis::Tools::ParameterContainer

          klass.parameter mapping_file: nil,
                          description: 'File that maps search term to identifier for metadata lookup.'

          klass.parameter mapping_sheet: nil,
                          description: 'Sheet in the mapping file to use. Only used for XLS format.'

          klass.parameter mapping_format: 'csv',
                          description: 'Format in which the mapping file is written.',
                          constraint: %w'tsv csv xls'

          klass.parameter mapping_headers: %w'key value',
                          description: 'Headers for the mapping file.'

          klass.parameter mapping_flags: [],
                          description: 'A list of column names that need to be interpreted as flags.'

          klass.parameter mapping_key: 'key',
                          description: 'Name of the column that contains the lookup value.'

          klass.parameter filter_keys: [],
                          desription: 'Names of the columns to filter on.'

          klass.parameter filter_values: [],
                          description: 'Values for the filter columns.' +
                              ' These values should be expressions as they will be evaluated.'

          klass.parameter required_fields: [],
              description: 'Columns that should be present and not empty.'

        end

        protected

        def result
          @result if @result
          options = {
              file: parameter(:mapping_file),
              sheet: parameter(:mapping_sheet),
              keys: [parameter(:mapping_key)],
              values: parameter(:mapping_headers),
              flags: parameter(:mapping_flags),
              required: parameter(:required_fields)
          }
          unless parameter(:filter_keys).size == parameter(:filter_values).size
            raise WorkflowError, 'Parameters :filter_keys and :filter_values should have the same number of values.'
          end
          options[:keys] = parameter(:filter_keys) + options[:keys]
          case parameter(:mapping_format)
            when 'csv'
              options[:col_sep] = ','
            when 'tsv'
              options[:col_sep] = "\t"
            else
              # do nothing
          end
          @result = load_mapping(options)
        end

        def mapping
          self.result[:mapping]
        end

        def flagged(flag = nil)
          return self.result[:flagged] unless flag
          self.result[:flagged][flag] || []
        end

        def lookup(term, value_name = nil)
          return term if self.mapping.blank?
          map = filter(parameter(:filter_values))[term]
          value_name.blank? ? map : map[value_name]
        end

        def filter(filter_values = [])
          filter_values.inject(self.mapping) { |map, fv| map[eval(fv)] }
        end

      end

    end
  end
end