require 'fileutils'

require 'libis/tools/xml_document'

require 'libis-ingester'
require 'libis/ingester/ftps_service'

module Libis
  module Ingester

    class Exporter < ::Libis::Ingester::Task

      parameter export_dir: '.', description: 'Directory where the export files will be copied'
      parameter export_key: 'item.label',
                description: 'Expression to collect the key value for the export file.'
      parameter export_format: 'tsv',
                description: 'Format of the export file.',
                constraint: %w'tsv csv xml yml'
      parameter export_header: true, description: 'Add header line to export file.'
      parameter item_types: ['Libis::Ingester::IntellectualEntity'], frozen: true
      parameter recursive: true, frozen: true

      protected

      def process(item)
        export_item(item)
        stop_processing_subitems
      end

      private

      # @param [Libis::Ingester::IntellectualEntity] item
      def export_item(item)
        unless item.pid
          warn "Object #{item.name} was not ingested fully.", item
          return
        end

        FileUtils.mkdir_p(parameter(:export_dir))
        export_file = File.join(parameter(:export_dir), "#{item.get_run.name}.#{parameter(:export_format)}")

        run_item = item.get_run
        unless run_item.nil? || run_item.properties['export_file']
          run_item.properties['export_file'] = export_file
          run_item.save!
        end
        key_value = eval(parameter(:export_key))

        open(export_file, 'a') do |f|
          case parameter(:export_format).to_sym
            when :tsv
              f.puts "KEY\tPID" if f.size == 0 && parameter(:export_header)
              f.puts "#{key_value}\t#{item.pid}"
            when :csv
              f.puts 'KEY,PID' if f.size == 0 && parameter(:export_header)
              f.puts "'#{key_value.gsub('\'','\'\'')}','#{item.pid.gsub('\'','\'\'')}'"
            when :xml
              f.puts '<?xml version="1.0" encoding="UTF-8"?>' if f.size == 0 && parameter(:export_header)
              f.puts "<item key=\"#{key_value}\">#{item.pid}</item>"
            when :yml
              f.puts '# Ingester export file' if f.size == 0 && parameter(:export_header)
              f.puts "- key: '#{key_value}'\n  value: '#{item.pid}'"
            else
              #nothing
          end

        end

        debug 'Item %s with pid %s exported.', key_value, item.pid

      end

    end
  end
end
