require 'libis/ingester/tasks/base/mapping'

require_relative 'metadata_alma_collector'
module Libis
  module Ingester

    class MetadataAlmaMapper < MetadataAlmaCollector
      include Base::Mapping

      protected

      def get_search_term(item)
        lookup(super(item))
      end

    end

  end
end