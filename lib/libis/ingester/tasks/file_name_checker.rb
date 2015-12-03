# encoding: utf-8

require 'libis/workflow'

module Libis
  module Ingester

    class FileNameChecker < ::Libis::Ingester::Task

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
          log_failed(item, 'File did not pass file name check.')
        end

      end

    end

  end
end
