require 'libis/ingester'
require 'libis/tools/metadata/dublin_core_record'

require_relative 'base/mapping'
require_relative 'metadata_collector'
module Libis
  module Ingester

    class MetadataFileMapper < MetadataCollector
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
