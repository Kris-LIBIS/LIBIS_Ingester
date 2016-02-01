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

      def search(term)
        @alma ||= parameter(:host) ? Libis::Services::Alma::WebService.new(parameter(:host)) : Libis::Services::Alma::WebService.new

        result = @alma.get_marc(term)
        raise Exception, "#{result[:error_type]} - #{result[:error_name]}" if result.is_a?(Hash)
        result = result.xpath('/bib/record').first rescue nil

        return result.blank? ? nil : Libis::Tools::Metadata::Marc21Record.new(result)

      rescue Exception => e
        raise Libis::WorkflowError, "Alma request failed: #{e.message}"
      end

    end

  end
end