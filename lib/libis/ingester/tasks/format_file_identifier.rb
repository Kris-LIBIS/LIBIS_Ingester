# encoding: utf-8

require 'libis/ingester'
require 'libis-format'

module Libis
  module Ingester

    class FormatFileIdentifier < ::Libis::Ingester::Task

      taskgroup :preprocessor

      description 'Tries to determine the format of a file.'

      help <<-STR.align_left
        This task will perform the format identification on each FileItem object in the ingest run. It relies completely
        on the format identification algorithms in Libis::Format::Identifier. If a format could not be determined, the
        MIME type 'application/octet-stream' will be set and a warning message is logged.
      STR

      parameter format_options: {}, type: 'hash',
                description: 'Set of options to pass on to the format identifier tool'

      parameter item_types: [Libis::Ingester::FileItem], frozen: true
      parameter recursive: true

      protected

      def process(item)
        result = Libis::Format::Identifier.get(item.fullpath, parameter(:format_options).key_strings_to_symbols)
        format = result[:formats][item.fullpath]
        mimetype = format[:mimetype]

        if mimetype
          debug "MIME type '#{mimetype}' detected.", item
        else
          warn "Could not determine MIME type. Using default 'application/octet-stream'.", item
        end

        item.properties['mimetype'] = mimetype || 'application/octet-stream'
        item.properties['puid'] = format[:puid] || 'fmt/unknown'
        item.properties['format_identification'] = format
      rescue => e
        raise Libis::WorkflowAbort, "Error during Format identification: #{e.message} @ #{e.backtrace.first}"
      end

    end

  end
end
