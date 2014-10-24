# encoding: utf-8

require 'LIBIS_Workflow'

module LIBIS
  module Ingester

    class FileChecker < ::LIBIS::Workflow::Task

      parameter filename_regexp: nil,
                description: 'Match files with names that match the given regular expession. Ignored if empty.'
      parameter mimetype_regexp: nil,
                description: 'Match files with MIME types that match the given regular expression. Ignored if empty.'

      def process(item)
        return unless item.is_a? ::LIBIS::Ingester::FileItem

        check_exists item
        check_file_name item
        check_mime_type item
      end

      def check_exists(item)
        raise ::LIBIS::WorkflowError, "File '#{item.filepath}' does not exist." unless File.exists? item.fullpath
      end

      def check_file_name(item)
        filter = options[:filename_regexp]
        return if filter.nil? or filter.empty?
        debug "Checking filename against '/#{filter}/'."
        filter = Regexp.new(filter) unless filter.is_a? Regexp

        unless item.name =~ filter
          log_failed(item, 'File did not pass file name check.')
        end

      end

      def check_mime_type(item)
        filter = options[:mimetype_regexp]
        return if filter.nil?
        debug "Checking MIME type against '/#{filter}/'."
        filter = Regexp.new(filter) unless filter.is_a? Regexp

        unless item.properties[:mimetype]
          warn 'Skipping file. MIME type not identified yet.'
          return
        end

        unless item.properties[:mimetype] =~ filter
          log_failed(item, 'File did not pass mimetype check.')
        end

      end

    end

  end
end
