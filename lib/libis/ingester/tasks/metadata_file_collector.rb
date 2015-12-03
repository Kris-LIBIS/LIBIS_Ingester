# encoding: utf-8

require 'libis/ingester'
require 'libis/tools/metadata/dublin_core_record'

require_relative 'metadata_collector'
module Libis
  module Ingester

    class MetadataFileCollector < MetadataCollector

      parameter location: '.',
                description: 'Directory where the metadata files can be found.'

      protected

      def get_record(item)
        term = get_search_term(item)
        return nil if term.blank?

        metadata_file = File.join(parameter(:location), term)
        unless File.exist?(metadata_file)
          debug 'Metadata file \'%s\' for item \'%s\' not found.', metadata_file, item.namepath
          return nil
        end
        begin
          return Libis::Tools::Metadata::DublinCoreRecord.new(metadata_file)
        rescue ArgumentError => e
          raise Libis::WorkflowError, "Dublin Core file '#{metadata_file}' parsing error: #{e.message}"
        end
      end

    end

  end
end