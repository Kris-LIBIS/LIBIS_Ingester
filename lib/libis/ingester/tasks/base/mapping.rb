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

          klass.parameter mapping_format: 'csv',
                    description: 'Format in which the mapping file is written.',
                    constraint: %w'tsv csv xls'

          klass.parameter mapping_headers: %w'key value',
                    description: 'Headers for the mapping file.'

          klass.parameter mapping_key: 'key',
                    description: 'Name of the column that contains the lookup value.'

          klass.parameter mapping_value: nil,
                    description: 'Optional name of the column to return. If empty, a Hash with all values will be returned.'

          klass.parameter filter_keys: [],
                    desription: 'Optional name of the column to filter on.'

          klass.parameter filter_values: [],
                    description: 'Optional value for the filter.'

          klass.parameter ignore_empty_value: false,
                    description: 'Ingore lines with empty value column.'

        end

        def apply_options(opts)
          super(opts)
          options = {
              file: parameter(:mapping_file),
              keys: [parameter(:mapping_key)],
              values: parameter(:mapping_headers),
          }
          if parameter(:ignore_empty_value) and !parameter(:mapping_value).blank?
            options[:required] = [parameter(:mapping_value)]
          end
          unless parameter(:filter_keys).size == parameter(:filter_values).size
            raise WorkflowError, 'Parameters :filter_keys and :filter_values should have the same number of values.'
          end
          options[:keys] = parameter(:filter_keys) + options[:keys] unless parameter(:filter_keys).blank?
          case parameter(:mapping_format)
            when 'csv'
              options[:col_sep] = ','
            when 'tsv'
              options[:col_sep] = "\t"
            else
              # do nothing
          end
          @mapping = load_mapping(options)[:mapping]
        end

        protected

        def lookup(term)
          return term if @mapping.blank?
          mapping = filter(parameter(:filter_values))[term]
          parameter(:mapping_value).blank? ? mapping : mapping[parameter(:mapping_value)]
        end

        def filter(filter_value)
          return @mapping if filter_value.blank?
          filter_value = eval(parameter(:filter_value))
          @mapping[filter_value]
        end

      end

    end
  end
end