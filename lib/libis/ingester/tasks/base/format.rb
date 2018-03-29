module Libis
  module Ingester
    module Base

      module Format

        protected

        def assign_format(format, item)
          mimetype = format[:mimetype]

          if mimetype
            debug "MIME type '#{mimetype}' detected.", item
          else
            warn "Could not determine MIME type. Using default 'application/octet-stream'.", item
          end

          item.properties['mimetype'] = mimetype || 'application/octet-stream'
          item.properties['puid'] = format[:puid] || 'fmt/unknown'
          item.properties['format_name'] = format[:format_name] if format[:format_name]
          item.properties['format_version'] = format[:format_version] if format[:format_version]
          item.properties['format_ext_mismatch'] = (format[:ext_mismatch] == "true")
          item.properties['format_tool'] = format[:tool] if format[:tool]
          item.properties['format_matchtype'] = format[:matchtype] if format[:matchtype]
          item.properties[:format_type] = format[:TYPE] if format[:TYPE]
          item.properties[:format_group] = format[:GROUP] if format[:GROUP]
          item.properties['format_alternatives'] = format[:alternatives]
          item.save!

        end

        def apply_formats(item, format_list, folder = nil)

          if item.is_a? Libis::Ingester::FileItem
            format = format_list[item.fullpath]
            format ||= format_list[item.namepath]
            format ||= format_list[File.relative_path(folder, File.absolute_path(item.fullpath))] if folder
            format ||= format_list[item.filename]
            assign_format(format, item) if format
          else
            item.each do |subitem|
              apply_formats(subitem, format_list, folder)
            end
          end

        end

        def process_messages(format_result, item)
          format_result[:messages].each do |msg|
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

        end

      end

    end
  end
end