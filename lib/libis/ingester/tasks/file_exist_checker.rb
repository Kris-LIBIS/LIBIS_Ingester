# encoding: utf-8

require 'libis/workflow'

module Libis
  module Ingester

    class FileExistChecker < ::Libis::Ingester::Task

      taskgroup :preprocessor

      description 'Check if a file exists'

      help <<-STR.align_left
        This task can be used when the collector creates FileItem objects from some external source without checking if
        the file referenced does exist. For each FileItem in the ingest run tree, a check will be performed if the file
        referenced by the object does exist and can be read. If not an error will be logged and the workflow will abort.
      STR

      parameter item_types: [Libis::Ingester::FileItem], frozen: true

      protected

      def process(item)
        raise ::Libis::WorkflowError, "File '#{item.filepath}' does not exist." unless
            File.exists?(item.fullpath) && File.readable?(item.fullpath)
      end

    end

  end
end
