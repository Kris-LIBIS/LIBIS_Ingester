require 'libis/ingester/tasks/base/mapping'

require_relative 'metadata_alma_collector'
module Libis
  module Ingester

    class MetadataAlmaMapper < ::Libis::Ingester::MetadataAlmaCollector
      include Base::Mapping

      parameter search_field: 'MMS',
                description: 'Column name of the column in the mapping table that contains the search value.'

      def apply_options(opts)
        super(opts)
        set = Set.new(parameter(:mapping_headers))
        set << parameter(:search_field)
        parameter(:mapping_headers, set.to_a)
        parameter(:required_fields, [parameter(:mapping_key), parameter(:search_field)])
      end

      protected

      def get_search_term(item)
        lookup(super(item), parameter(:search_field))
      end

    end

  end
end