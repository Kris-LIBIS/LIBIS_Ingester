require 'libis/ingester'
require 'libis/metadata/dublin_core_record'

require_relative 'metadata_search_collector'
module Libis
  module Ingester

    class MetadataFileCollector < MetadataSearchCollector

      parameter location: '.',
                description: 'Directory where the metadata files can be found.'

      protected

      def search(term)
        metadata_file = File.join(parameter(:location), term)
        return nil unless File.exist?(metadata_file)

        begin
          return Libis::Metadata::DublinCoreRecord.new(metadata_file)
        rescue ArgumentError => e
          raise Libis::WorkflowError, "Dublin Core file '#{metadata_file}' parsing error: #{e.message}"
        end
      end

    end

  end
end