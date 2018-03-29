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

        This task will first collect all file paths in the tree and then call the format identification once for all 
        files. Since Droid is part of the file identification process and starting it is slow, this task will perform
        faster than the file-by-file approach by the FormatIdentifier when there are many files involved. However, this
        also means that the format information of all the files needs to be kept in memory and might slow down if a very
        large number of files need to be identified. Moreover, some tools do not accept a read-from-file input method,
        which means that all file paths have to be passed via the command line. Command line size limits may cause these
        tools to fail for many files, depending on the number of files and the length of the paths. In that case the
        FormatDirCollection might be a better option, at least if the files are not dispersed and can be accessed via a
        single folder.
      STR

      parameter format_options: {}, type: 'hash',
                description: 'Set of options to pass on to the format identifier tool'

      parameter item_types: [Libis::Ingester::Run], frozen: true
      parameter recursive: false

      protected

      def process(item)
        file_list = collect_filepaths(item)
        format_list = Libis::Format::Identifier.get(file_list, parameter(:format_options).key_strings_to_symbols)
        process_messages(format_list, item)
        apply_formats(item, format_list[:formats])
      rescue => e
        raise Libis::WorkflowAbort, "Error during Format identification: #{e.message} @ #{e.backtrace.first}"
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
