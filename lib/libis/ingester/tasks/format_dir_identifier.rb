require 'libis/ingester'
require 'libis-format'
require 'libis/tools/extend/hash'
require 'yard/core_ext/file'

require_relative 'base/format'

module Libis
  module Ingester

    class FormatDirIdentifier < ::Libis::Ingester::Task
      include ::Libis::Ingester::Base::Format

      taskgroup :preprocessor

      description 'Tries to determine the format of all files in a directories.'

      help <<-STR.align_left
        This task will perform the format identification on each FileItem object in the ingest run. It relies completely
        on the format identification algorithms in Libis::Format::Identifier. If a format could not be determined, the
        MIME type 'application/octet-stream' will be set and a warning message is logged.

        Note that this task will first determine the formats of all files in the given folder and subfolders (if deep_scan
        is set to true). It will then iterate over each known FileItem to find the matching file format information. The
        upside of this approach is that it requires the start of each of the underlying tools only once for the whole set
        of files, compared with once for each file for the FormatIdentifier. It will therefore perform significantly
        faster than the latter since starting Droid is very slow. However, if there are a lot of files, this also means
        that the format information for a lot of files needs to be kept in memory during the whole task run and this
        task will be more memory-intensive than it's file-by-file counterpart. If there are also a lot of files in the 
        source folder that are ignored, these will also be format-identified by this task, resulting in a significant 
        overhead.

        You should therefore carefully consider which task to use. Of course this task will only be usable if all source
        files are stored in a single folder tree. If the files are disparsed over a large set of directories, it makes
        no sense in using this task to format-identify the whole dir tree and the FormatIdentifier task will probably
        be faster in that case.
      STR

      parameter folder: nil,
                description: 'Directory with files that need to be idententified'
      parameter deep_scan: true,
                description: 'Also identify files recursively in subfolders?'
      parameter format_options: {}, type: 'hash',
                description: 'Set of options to pass on to the format identifier tool'

      parameter item_types: [Libis::Ingester::Run], frozen: true
      parameter recursive: false

      protected

      def process(item)
        unless File.directory?(parameter(:folder))
          raise Libis::WorkflowAbort, "Value of 'folder' parameter in FormatDirIngester should be a directory name."
        end
        options = {
            recursive: parameter(:deep_scan),
            base_dir: parameter(:folder)
        }.merge(parameter(:format_options).key_strings_to_symbols)
        format_list = Libis::Format::Identifier.get(parameter(:folder), options)
        process_messages(format_list, item)
        apply_formats(item, format_list[:formats], parameter(:folder))
      end

    end

  end
end
