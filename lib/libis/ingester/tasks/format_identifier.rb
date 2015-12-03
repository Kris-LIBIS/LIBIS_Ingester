# encoding: utf-8

require 'libis/ingester'
require 'libis-format'

module Libis
  module Ingester

    class FormatIdentifier < ::Libis::Ingester::Task

      parameter formats: nil,
                description: 'Format file to load.'

      parameter item_types: [Libis::Ingester::FileItem], frozen: true

      protected

      def pre_process(item)
        super
        skip_processing_item if item.properties[:mimetype] && item.properties[:puid]
      end

      def process(item)
        format = Libis::Format::Identifier.get(item.fullpath, formats: parameter(:formats)) rescue {}

        mimetype = format[:mimetype]

        if mimetype
          info "MIME type '#{mimetype}' detected."
        else
          warn "Could not determine MIME type. Using default 'application/octet-stream'."
          mimetype = 'application/octet-stream'
        end

        item.properties[:mimetype] = mimetype
        item.properties[:puid] = format[:puid]
      end

    end

  end
end
