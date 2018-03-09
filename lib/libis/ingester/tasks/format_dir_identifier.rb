# encoding: utf-8

require 'libis/ingester'
require 'libis-format'
require 'libis/tools/extend/hash'
require 'yard/core_ext/file'

module Libis
  module Ingester

    class FormatDirIdentifier < ::Libis::Ingester::Task

      taskgroup :preprocessor

      description 'Tries to determine the format of all files in a directories.'

      help <<-STR.align_left
        This task will perform the format identification on each FileItem object in the ingest run. It relies completely
        on the format identification algorithms in Libis::Format::Identifier. If a format could not be determined, the
        MIME type 'application/octet-stream' will be set and a warning message is logged.
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
        format_list[:messages].each do |msg|
          case msg[0]
            when :debug
              debug msg[1], item
            when :info
              info msg[1], item
            when :warn
              warn msg[1], item
            when :error
              error msg[1], item
            when :fatal
              fatal_error msg[1], item
            else
              info "#{msg[0]}: #{msg[1]}", item
          end
        end
        apply_formats(item, format_list[:formats])
      end

      def apply_formats(item, format_list)

        if item.is_a? Libis::Ingester::FileItem
          format =
              format_list[item.namepath] ||
              format_list[item.filename] ||
              format_list[File.relative_path(parameter(:folder), File.absolute_path(item.fullpath))]
          if format.empty?
            warn "Could not determine MIME type. Using default 'application/octet-stream'.", item
            format = {mimetype: 'application/octet-stream'}
          else
            debug "MIME type '#{format[:mimetype]}' detected.", item
          end
          item.properties['mimetype'] = format[:mimetype] || 'application/octet-stream'
          item.properties['puid'] = format[:puid]
          item.properties['format_identification'] = format
          item.save!
        else
          item.each do |subitem|
            apply_formats(subitem, format_list)
          end
        end

      end

    end

  end
end
