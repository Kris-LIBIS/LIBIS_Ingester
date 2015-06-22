# encoding: utf-8

require 'libis/ingester'
require 'libis-format'

module LIBIS
  module Ingester

    class FormatIdentifier < ::Libis::Ingester::Task

      parameter formats: nil,
                description: 'Format file to load.'

      def process(item)
        return unless item.is_a? ::Libis::Ingester::FileItem

        mimetype = Libis::Format::Identifier.get(item.fullpath, formats: parameter(:formats))

        if mimetype
          info "MIME type '#{mimetype}' detected."
        else
          warn "Could not determine MIME type. Using default 'application/octet-stream'."
          mimetype = 'application/octet-stream'
        end

        item.properties[:mimetype] = mimetype
      end

    end

  end
end
