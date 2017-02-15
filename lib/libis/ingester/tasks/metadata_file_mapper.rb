require 'libis/ingester'
require 'libis/tools/metadata/dublin_core_record'

require_relative 'base/mapping'
require_relative 'metadata_file_collector'
module Libis
  module Ingester

    class MetadataFileMapper < MetadataFileCollector
      include Base::Mapping

      parameter metadata_file_field: 'metadata_file',
                description: 'The header value of the column that contains the name of the metadata file.'

      protected

      def search(term)
        file_name = lookup(term, parameter(:metadata_file_field))
        unless file_name
          warn "No matching metadata file name found for #{term}."
          return nil
        end
        metadata_file = File.join(parameter(:location), file_name)
        unless File.exist?(metadata_file)
          raise Libis::WorkflowError, "File #{metadata_file} not found."
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
