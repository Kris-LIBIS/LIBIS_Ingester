# encoding: utf-8
require 'libis-ingester'
require 'csv'

module Libis
  module Ingester

    class Labeler < Libis::Ingester::Task

      parameter mapping_file: nil,
                description: 'Path of mapping file.'
      parameter mapping_format: 'csv',
                description: 'Format in which the mapping file is written.',
                constraint: %w'tsv csv'
      parameter lookup_expr: 'item.name',
                description: 'A Ruby expression that returns the lookup value.'
      parameter lookup_field: 'Name',
                description: 'The name of the lookup field in the mapping file.'
      parameter label_field: 'Label',
                description: 'The name of the label field in the mapping file.'
      parameter mapping_expr: nil,
                description: 'A Ruby expression that returns the new label.'

      parameter recursive: true

      parameter item_types: [Libis::Ingester::FileItem]

      def initialize(parent, cfg = {})
        super(parent, cfg)
        @mapping = {}
        mapping_file = parameter(:mapping_file)
        return if mapping_file.blank?
        unless File.exist?(mapping_file) && File.readable?(mapping_file)
          raise Libis::WorkflowError, "Cannot open mapping file '#{mapping_file}'"
        end
        col_sep = case parameter(:mapping_format)
                    when 'tsv'
                      "\t"
                    when 'csv'
                      ','
                    else
                      raise Libis::WorkflowError "Unsupported mapping format: #{parameter(:mapping_format)}"
                  end
        begin
          csv = CSV.read(mapping_file, col_sep: col_sep, headers: true)
          lookup = parameter(:lookup_field)
          label = parameter(:label_field)
          csv.each do |row|
            @mapping[row[lookup]] = row[label]
          end
        rescue CSV::MalformedCSVError
          raise Libis::WorkflowError "Error parsing mapping file #{mapping_file}"
        end
      end

      protected

      def process(item)
        unless @mapping.empty?
          lookup = eval(parameter(:lookup_expr))
          label = @mapping[lookup]
          if label
            item.label = label
            status_counter(item)
            item.save!
          else
            warn 'Could not find label in mapping table', item
          end
        end
      end

      private

      attr_accessor :file_registry

    end

  end
end
