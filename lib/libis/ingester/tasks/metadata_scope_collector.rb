# encoding: utf-8

require 'libis/ingester'
require 'libis/services/scope/search'
require 'libis/tools/metadata/dublin_core_record'

require_relative 'metadata_search_collector'
module Libis
  module Ingester

    class MetadataScopeCollector < ::Libis::Ingester::MetadataSearchCollector

      parameter converter: 'Scope'
      parameter term_type: 'REPCODE',
                desrciption: 'Type of term value that will be passed',
                constraint: %w(REPCODE ID)

      protected

      def search(term)
        unless @scope
          @scope = ::Libis::Services::Scope::Search.new
          @scope.connect(
              ::Libis::Ingester::Config['scope_user'],
              ::Libis::Ingester::Config['scope_passwd']
          )
        end

        debug "Querying scope with term '#{term}' and type '#{parameter(:term_type)}'"
        @scope.query(term, type: parameter(:term_type))

        @scope.next_record do |doc|
          debug "Found record with title '#{doc.value('//dc:title')}"
          return ::Libis::Tools::Metadata::DublinCoreRecord.new(doc.to_xml)
        end

      rescue Exception => e
        raise ::Libis::WorkflowError, "Scope request failed: #{e.message}"
      end

    end

  end
end