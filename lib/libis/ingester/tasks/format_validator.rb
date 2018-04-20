require 'libis/ingester'
require 'libis/format/type_database'
require 'htmltoword'

require_relative 'base/format'

module Libis
  module Ingester

    class FormatValidator < ::Libis::Ingester::Task
      include ::Libis::Ingester::Base::Format

      taskgroup :preprocessor

      description 'Validates the file formats.'

      help <<-STR.align_left
        This task will validate files based on their format specification. It will reject files with known issues like password protection
        and files whose extension does not match the detected file format.
      STR

      parameter ext_mismatch: 'FAIL', type: :string, constraint: %w'FAIL WARN FIX',
                description: 'Action to take when an extension mismatch is found. Valid values are:\n' +
                    '- FAIL: report this as an error and stop processing this object\n' +
                    '- WARN: report this as an error and continue (may cause issues later in Rosetta)\n' +
                    '- FIX: change the file extension and continue'
      parameter encrypted_doc: 'FAIL', type: :string, constraint: %w'FAIL WARN DUMMY',
                description: 'Action to take when an encrypted document is found. Valid values are:\n' +
                    '- FAIL: report this as an error and stop processing this object\n' +
                    '- WARN: report this as an error and continue (may cause issues later during ingest or in Rosetta)\n' +
                    '- DUMMY: create a dummy file with a message why the file was rejected'

      parameter item_types: [Libis::Ingester::FileItem], frozen: true
      parameter recursive: true

      protected

      def process(item)

        msg = case item.properties['puid']
              when 'fmt/494'
                'Microsoft Office Encrypted Document'
              when 'fmt/754'
                'password protected Microsoft Word Document'
              when 'fmt/755'
                'password protected Microsoft Word Document Template'
              else
                nil
              end

        if msg
          case parameter(:encrypted_doc)
          when 'FAIL'
            raise Libis::WorkflowError, "Found #{msg}: #{item.filepath}"
          when 'WARN'
            warn "Found #{msg}: #{item.filepath}"
          when 'DUMMY'
            replace_with_dummy(item, "File <i>#{item.filepath}</i> is a #{msg}")
          else
            raise Libis::WorkflowAbort, "Unknown value for encrypted_doc parameter encountered."
          end
        end

        if item.properties['format_ext_mismatch']
          format_type = item.properties[:format_type]
          extensions = format_type ? Libis::Format::TypeDatabase.type_extentions(format_type) : []
          message = 'Found document with wrong extension `%s`; format is %s%s, puid: %s, valid extensions: %s' %
              [
                  File.extname(item.filepath),
                  item.properties['format_name'],
                  item.properties['format_version'].blank? ? '' : " (#{item.properties['format_version']})",
                  item.properties['puid'],
                  extensions.map {|x| ".#{x}"}.join(' ')
              ]
          case parameter(:ext_mismatch)
          when 'FAIL'
            raise Libis::WorkflowError, message
          when 'WARN'
            warn message
          when 'FIX'
            warn message
            if (ext = extensions.first)
              old_name = item.properties['filename']
              new_name = File.join(File.dirname(old_name), "#{File.basename(old_name, '.*')}.#{ext}")
              File.rename(old_name, new_name)
              item.properties['filename'] = new_name
              item.save!
              warn "Changed file name to '#{File.basename(new_name)}'."
            else
              message = 'Could not fix extenstion of file %s as no extension for the format (%s - %s - %s) is known in the type database' %
                  [item.filepath, item.properties['puid'], item.properties['format_name'], item.properties['format_version']]
              raise Libis::WorkflowError, message
            end
          else
            warn message
          end
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

      def replace_with_dummy(item, message)
        html = '<html><head></head><body><h1/><h1>%s</h1><h1/>%s</body></html>' % [
            'The preservation system rejected this file for the following reason:',
            "File <i>#{item.fullpath}</i> is a <b>#{message}</b>"
        ]
        Htmltoword.config.custom_templates_path = File.join(Libis::Ingester::ROOT_DIR, 'config')
        Htmltoword::Document.create_and_save(html, item.fullpath, 'Warning')
        result = Libis::Format::Identifier.get(item.fullpath) || {}
        process_messages(result, item)
        apply_formats(item, result[:formats])
      end

    end

  end
end
