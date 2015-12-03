# encoding: utf-8

require 'libis/ingester'
require 'libis/services/alma/web_service'
require 'libis/tools/metadata/marc21_record'

require_relative 'metadata_collector'
module Libis
  module Ingester

    class MetadataAlmaCollector < MetadataCollector

      parameter host: nil,
                description: 'URL of the Alma web service.'
      parameter converter: 'Kuleuven'

      protected

      def get_record(item)
        term = get_search_term(item)
        return nil if term.blank?

        RestClient.log = 'stdout'
        @alma ||= parameter(:host) ? Libis::Services::Alma::WebService.new(parameter(:host)) : Libis::Services::Alma::WebService.new
        result = @alma.get_marc(term).xpath('/bib/record').first rescue nil

        if result.blank?
          debug 'Metadata for item \'%s\' not found.', item.namepath
          return nil
        end

        return Libis::Tools::Metadata::Marc21Record.new(result)

      rescue Exception => e
        raise Libis::WorkflowError, "Failed to get metadata: #{e.message}"
      end

    end

  end
end