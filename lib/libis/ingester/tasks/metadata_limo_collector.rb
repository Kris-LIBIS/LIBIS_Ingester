# encoding: utf-8

require 'libis/ingester'
require 'libis/tools/metadata/marc21_record'
require 'libis/services/primo'

require_relative 'metadata_collector'
module Libis
  module Ingester

    class MetadataLimoCollector < MetadataCollector

      parameter host: nil,
                description: 'URL for the Limo web service.'
      parameter converter: 'Kuleuven'

      protected

      def get_record(item)
        term = get_search_term(item)
        return nil if term.blank?

        @limo ||= Libis::Services::Primo::Limo.new(parameter(:host))

        result = @limo.get_marc(term)
        raise Exception, "#{result[:error_type]} - #{result[:error_name]}" if result.is_a?(Hash)
        result = result.root rescue nil

        if result.blank?
          debug 'Metadata for item \'%s\' not found.', item.namepath
          return nil
        end

        return Libis::Tools::Metadata::Marc21Record.new(result)

      rescue Exception => e
        raise Libis::WorkflowError, "Limo request failed: #{e.message}"
      end

    end

  end
end