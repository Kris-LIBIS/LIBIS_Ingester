require 'libis/ingester'
require 'libis-format'
require 'libis/tools/extend/hash'

require_relative 'base/format'

module Libis
  module Ingester

    class FormatIdentifier < ::Libis::Ingester::Task
      include ::Libis::Ingester::Base::Format

      taskgroup :preprocessor

      description 'Tries to determine the format of the files found.'

      help <<-STR.align_left
        This task will perform the format identification on each FileItem object in the ingest run. It relies completely
        on the format identification algorithms in Libis::Format::Identifier. If a format could not be determined, the
        MIME type 'application/octet-stream' will be set and a warning message is logged.
      STR

      parameter format_options: {}, type: 'hash',
                description: 'Set of options to pass on to the format identifier tool'

      parameter item_types: [Libis::Ingester::Run], frozen: true
      parameter recursive: true

      protected

      def process(item)
        file_list = collect_filepaths(item)
        format_list = Libis::Format::Identifier.get(file_list, parameter(:format_options).key_strings_to_symbols)
        format_list[:messages].each do |msg|
          case msg[0]
          when :debug
            debug msg[1], item
          when :info
            info msg[1], item
          when :error
            error msg[1], item
          when :fatal
            fatal_error msg[1], item
          else
            info "#{msg[0]}: #{msg[1]}", item
          end
        end
        apply_formats(item, format_list[:formats])
      rescue => e
        raise Libis::WorkflowAbort, "Error during Format identification: #{e.message} @ #{e.backtrace.first}"
      end

      def apply_formats(item, format_list)

        if item.is_a? Libis::Ingester::FileItem
          format = format_list[item.fullpath]
          assign_format(item, format)
        else
          item.each do |subitem|
            apply_formats(subitem, format_list)
          end
        end

      end

      def collect_filepaths(item)
        return File.absolute_path(item.fullpath) if item.is_a? Libis::Ingester::FileItem
        item.map do |subitem|
          collect_filepaths(subitem)
        end.flatten.compact
      end

    end

  end
end
