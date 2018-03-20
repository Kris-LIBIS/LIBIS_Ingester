# encoding: utf-8

require 'libis/ingester'

module Libis
  module Ingester

    class FormatValidator < ::Libis::Ingester::Task

      taskgroup :preprocessor

      description 'Validates the file formats.'

      help <<-STR.align_left
        This task will validate files based on their format specification. It will reject files with known issues like password protection
        and files whose extension does not match the detected file format.
      STR

      parameter fail_ext_mismatch: false, type: 'boolean',
                description: 'Fail the task when an extension mismatch is found if this parameter is set to true. Ony warn otherwise.'

      parameter item_types: [Libis::Ingester::FileItem], frozen: true
      parameter recursive: true

      protected

      def process(item)

        raise Libis::WorkflowError, "Found Microsoft Office Encrypted Document: #{item.filepath}" if item.properties['puid'] == 'fmt/494'

        raise Libis::WorkflowError, "Found Microsoft Word Document that is password protected: #{item.filepath}" if item.properties['puid'] == 'fmt/754'

        raise Libis::WorkflowError, "Found Microsoft Word Document Template that is password protected: #{item.filepath}" if item.properties['puid'] == 'fmt/755'

        if item.properties['format_ext_mismatch']
          message = 'Found document with wrong extension: %s (%s - %s - %s)' %
              [item.filepath, item.properties['puid'], item.properties['format_name'], item.properties['format_version']]
          parameter(:fail_ext_mismatch) ? raise(Libis::WorkflowError, message) : warn message
        end
      end

      def apply_formats(item, format_list)

        if item.is_a? Libis::Ingester::FileItem
          format = format_list[item.fullpath]
          if format.empty?
            warn "Could not determine MIME type. Using default 'application/octet-stream'.", item
          else
            debug "MIME type '#{format[:mimetype]}' detected.", item
          end
          item.properties['mimetype'] = format[:mimetype] || 'application/octet-stream'
          item.properties['puid'] = format[:puid] || 'fmt/unknown'
          item.properties['format_identification'] = format
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
