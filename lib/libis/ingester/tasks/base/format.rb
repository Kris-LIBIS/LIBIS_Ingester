module Libis
  module Ingester
    module Base

      module Format
        def assign_format(item, format)
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
      end

    end
  end
end