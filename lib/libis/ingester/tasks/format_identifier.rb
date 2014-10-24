# encoding: utf-8

require 'LIBIS_Workflow'
require 'LIBIS_Tools'

module LIBIS
  module Ingester

    class FormatIdentifier < ::LIBIS::Workflow::Task

      parameter formats: nil,
                description: 'Format file to load.'

      def process(item)
        return unless item.is_a? ::LIBIS::Ingester::FileItem

        mimetype = LIBIS::Tools::Format::Identifier.get(item.fullpath, options[:formats])

        unless mimetype
          warn "Could not determine MIME type. Using default 'application/octet-stream'."
          mimetype = 'application/octet-stream'
        else
          info "MIME type '#{mimetype}' detected."
        end

        item.properties[:mimetype] = mimetype
      end

    end

  end
end
