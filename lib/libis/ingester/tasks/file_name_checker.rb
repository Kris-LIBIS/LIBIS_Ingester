# encoding: utf-8

require 'libis/workflow'

module Libis
  module Ingester

    class FileNameChecker < ::Libis::Ingester::Task

      taskgroup :preprocessor

      description 'Checks the names of files against a regular expression.'

      help <<-STR.align_left
        This task will check each FileItem found and match its file name against the regular expression in the
        'filename_regexp' parameter. Failures will lead to error messages and an interrupted ingest workflow.
      STR
      parameter filename_regexp: nil,
                description: 'Match files with names that match the given regular expession. Ignored if empty.'

      parameter item_types: [Libis::Ingester::FileItem], frozen: true

      protected

      def process(item)
        filter = parameter(:filename_regexp)
        return if filter.nil? or filter.empty?
        debug "Checking filename against '/#{filter}/'."
        filter = Regexp.new(filter) unless filter.is_a? Regexp

        unless item.name =~ filter
          error item, 'File did not pass file name check.'
          set_status item, :FAILED
        end

      end

    end

  end
end
