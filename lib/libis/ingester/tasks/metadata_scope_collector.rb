# encoding: utf-8

require 'libis/ingester'
require 'libis/services/scope/search'
require 'libis/tools/metadata/dublin_core_record'

require_relative 'metadata_search_collector'
module Libis
  module Ingester

    class MetadataScopeCollector < ::Libis::Ingester::MetadataSearchCollector

      parameter converter: 'Scope'

      protected

      def search(term)
        unless @scope
          @scope = ::Libis::Services::Scope::Search.new
          @scope.connect(
              ::Libis::Ingester::Config['scope_user'],
              ::Libis::Ingester::Config['scope_passwd']
          )
        end
        @scope.query(term)

        @scope.next_record { |doc| return ::Libis::Tools::Metadata::DublinCoreRecord.new(doc.to_xml) }

      rescue Exception => e
        raise ::Libis::WorkflowError, "Scope request failed: #{e.message}"
      end

    end

  end
end