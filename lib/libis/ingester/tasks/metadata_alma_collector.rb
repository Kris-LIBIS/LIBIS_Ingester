# encoding: utf-8

require 'libis/ingester'
require 'libis/services/alma/sru_service'
require 'libis/tools/metadata/marc21_record'
require 'open-uri'

require_relative 'metadata_collector'
module Libis
  module Ingester

    class MetadataAlmaCollector < MetadataCollector

      parameter host: nil,
                description: 'URL of the Alma web service.'
      parameter converter: 'Kuleuven'

      protected

      def search(term)
        @alma ||= parameter(:host) ?
            Libis::Services::Alma::SruService.new(parameter(:host)) :
            Libis::Services::Alma::SruService.new

        field = parameter(:field) || 'alma.mms_id'
        result = @alma.search(field, URI::encode("\"#{term}\""))
        warn "Multiple records found for #{field}=#{term}" if result.size > 1

        return result.empty? ? nil : Libis::Tools::Metadata::Marc21Record.new(result.first.root)

      rescue Exception => e
        raise Libis::WorkflowError, "Alma request failed: #{e.message}"
      end

    end

  end
end