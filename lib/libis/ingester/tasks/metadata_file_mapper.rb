require_relative 'metadata_file_collector'
require_relative 'base/mapping'
module Libis
  module Ingester

    class MetadataMapper < MetadataFileCollector
      include Base::Mapping

      protected

      def search(term)
        super(lookup(term))
      end

    end

  end
end
