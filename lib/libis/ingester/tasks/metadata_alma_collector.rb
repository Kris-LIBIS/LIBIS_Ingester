require 'libis/ingester'
require 'libis/ingester/tasks/base/alma_search'

require_relative 'metadata_search_collector'
module Libis
  module Ingester

    class MetadataAlmaCollector < ::Libis::Ingester::MetadataSearchCollector
      include Base::AlmaSearch

      parameter converter: 'Kuleuven'

    end

  end
end