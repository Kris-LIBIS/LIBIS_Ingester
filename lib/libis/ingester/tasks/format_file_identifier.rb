require 'libis/ingester'
require 'libis-format'

require_relative 'base/format'

module Libis
  module Ingester

    class FormatFileIdentifier < ::Libis::Ingester::Task
      include ::Libis::Ingester::Base::Format

      taskgroup :preprocessor

      description 'Tries to determine the format of a file.'

      help <<-STR.align_left
        This task will perform the format identification on each FileItem object in the ingest run. It relies completely
        on the format identification algorithms in Libis::Format::Identifier. If a format could not be determined, the
        MIME type 'application/octet-stream' will be set and a warning message is logged.

        Note: consider using the FormatDirIdentifier if possible, since the latter will outperform this task easily with
        a factor of ten on large file sets. Please read the documentation on FileDirIdentifier on when to use which task.
      STR

      parameter format_options: {}, type: 'hash',
                description: 'Set of options to pass on to the format identifier tool'

      parameter item_types: [Libis::Ingester::FileItem], frozen: true
      parameter recursive: true

      protected

      def process(item)
        result = Libis::Format::Identifier.get(item.fullpath, parameter(:format_options).key_strings_to_symbols)
        process_messages(result, item)
        assign_format(item, result[:formats].first)
      rescue => e
        raise Libis::WorkflowAbort, "Error during Format identification: #{e.message} @ #{e.backtrace.first}"
      end

    end

  end
end
