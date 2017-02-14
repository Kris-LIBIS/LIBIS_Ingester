# encoding: utf-8

require 'libis/workflow'

module Libis
  module Ingester

    class FileExistChecker < ::Libis::Ingester::Task

      taskgroup :preprocessor

      parameter item_types: [Libis::Ingester::FileItem], frozen: true

      protected

      def process(item)
        raise ::Libis::WorkflowError, "File '#{item.filepath}' does not exist." unless File.exists?(item.fullpath)
      end

    end

  end
end
