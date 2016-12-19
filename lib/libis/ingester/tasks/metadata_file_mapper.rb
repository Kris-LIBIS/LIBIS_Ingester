require_relative 'metadata_file_collector'
require_relative 'base/mapping'
module Libis
  module Ingester

    class MetadataMapper < MetadataFileCollector
      include Base::Mapping

      protected

      def search(term)
        record = Libis::Tools::Metadata::DublinCoreRecord.new
        lookup(term).each do |key, value|
          next unless key =~ /^\s*<([^>]+)>(\d\s)*$/
          record.add_node($1.strip, value)
        end
        record
      end

    end

  end
end
