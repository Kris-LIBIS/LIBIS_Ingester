# encoding: utf-8

require 'libis/workflow'

module Libis
  module Ingester

    class FileMimetypeChecker < ::Libis::Ingester::Task

      taskgroup :preprocessor

      parameter mimetype_regexp: nil,
                description: 'Match files with MIME types that match the given regular expression. Ignored if empty.'

      parameter item_types: [Libis::Ingester::FileItem], frozen: true

      protected

      def process(item)
        filter = parameter(:mimetype_regexp)
        return if filter.nil?
        debug "Checking MIME type against '/#{filter}/'."
        filter = Regexp.new(filter) unless filter.is_a? Regexp

        unless item.properties['mimetype']
          warn 'Skipping file. MIME type not identified yet.'
          return
        end

        unless item.properties['mimetype'] =~ filter
          error item, 'File did not pass mimetype check.'
          set_status item, :FAILED
        end

      end

    end

  end
end
