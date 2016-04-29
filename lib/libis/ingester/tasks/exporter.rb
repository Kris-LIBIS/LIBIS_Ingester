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
              f.puts "KEY\tPID\tURL" if f.size == 0 && parameter(:export_header)
              f.puts "#{for_tsv(key_value)}\t#{for_tsv(item.pid.to_s)}" +
                         "\t#{for_tsv("http://resolver.libis.be/#{item.pid.to_s}/representation")}"
            when :csv
              f.puts 'KEY,PID,URL' if f.size == 0 && parameter(:export_header)
              f.puts "#{for_csv(key_value)},#{for_csv(item.pid.to_s)}" +
                         ",#{for_csv("http://resolver.libis.be/#{item.pid.to_s}/representation")}"
            when :xml
              f.puts '<?xml version="1.0" encoding="UTF-8"?>' if f.size == 0 && parameter(:export_header)
              f.puts '<item' +
                         " key=\"#{for_xml(key_value)}\"" +
                         " pid=\"#{for_xml(item.pid)}\"" +
                         " url=\"#{for_xml("http://resolver.libis.be/#{item.pid.to_s}/representation")}\"" +
                         ' />'
            when :yml
              f.puts '# Ingester export file' if f.size == 0 && parameter(:export_header)
              f.puts "- key: #{for_yml(key_value)}" +
                         "\n  value: #{for_yml(item.pid.to_s)}" +
                         "\n  url: #{for_yml("http://resolver.libis.be/#{item.pid.to_s}/representation")}"
            else
              #nothing
          end

        end

        debug 'Item %s with pid %s exported.', key_value, item.pid

      end

      def for_tsv(string)
        string =~ /\t\n/ ? "\"#{string.gsub('"', '""')}\"" : string
      end

      def for_csv(string)
        string =~ /,\n/ ? "\"#{string.gsub('"', '""')}\"" : string
      end

      def for_xml(string, type = :attr)
        string.encode(xml: type)
      end

      def for_yml(string)
        string.inspect.to_yaml
      end

    end
  end
end
