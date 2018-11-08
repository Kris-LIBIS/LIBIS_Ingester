require 'libis/ingester'
require 'libis/metadata'

module Libis
  module Ingester
    module Base
      class MetadataSearch
        include Libis::Tools::Logger

        # @param [String, Libis::Ingester::MetadataSearchConfig] config
        def initialize(config)
          if config.is_a? Libis::Ingester::MetadataSearchConfig
            @config = config
          else
            @config = Libis::Ingester::MetadataSearchConfig.find_by(config)
            raise Libis::WorkflowAbort, "Metadata search configuration '#{config}' not found." unless @config
          end
        end

        # @param [String] key
        def search(key)
          # noinspection RubyResolve
          record = case @config.cms_type
                   when :alma
                     alma_search(key)
                   when :scope
                     scope_search(key)
                   else
                     raise Libis::WorkflowAbort, "Unknown CMS type '#{@config.cms_type}'"
                   end

          return nil unless record

          debug "Found record with title '#{record.title}'"

          record_mapping(record, @config.mapping)
        end

        # @param [String] term
        def alma_search(term)
          @alma ||= ::Libis::Services::Alma::SruService.new(@config.url)

          field = @config.field
          debug "Querying alma with term '#{term}' for field '#{field}'"
          result = @alma.search(field, URI::encode("\"#{term}\""), @config.library)
          warn "Multiple records found for #{field}=#{term}" if result.size > 1

          return nil if result.empty?

          ::Libis::Metadata::Marc21Record.new(result.first.root)

        rescue Exception => e
          raise ::Libis::WorkflowError, "Alma request failed: #{e.message}"
        end

        # @param [String] term
        def scope_search(term)
          @scope ||= ::Libis::Services::Scope::Search.new.connect_url(@config.url)

          field = @config.field
          debug "Querying scope with term '#{term}' and type '#{field}'"
          @scope.query(term, type: field)

          @scope.next_record do |doc|
            return ::Libis::Metadata::DublinCoreRecord.new(doc.to_xml)
          end

        rescue Exception => e
          raise ::Libis::WorkflowError, "Scope request failed: #{e.message}"
        end

        # @param [Libis::Metadata::Marc21Record, Libis::Metadata::DublinCoreRecord] record
        def record_mapping(record, mapping)
          return record if mapping.blank?
          mapper_class = "Libis::Metadata::Mappers::#{mapping}".constantize

          raise Libis::WorkflowAbort, "Metadata converter class `#{mapping}` not found." unless mapper_class

          record.extend mapper_class
          record.to_dc
        end

      end
    end
  end
end