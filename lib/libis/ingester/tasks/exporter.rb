require 'fileutils'

require 'libis/tools/xml_document'

require 'libis-ingester'
require 'libis/ingester/ftps_service'

module Libis
  module Ingester

    class Exporter < ::Libis::Ingester::Task

      parameter export_dir: '.', description: 'Directory where the export files will be copied'
      parameter export_key: 'item.name',
                description: 'Expression to collect the key value for the export file.'
      parameter export_format: 'tsv',
                description: 'Format of the export file.',
                constraint: %w'tsv csv xml yml'
      parameter export_header: true, description: 'Add header line to export file.'
      parameter item_types: %w(Libis::Ingester::IntellectualEntity)
      parameter recursive: true, frozen: true

      protected

      def process(item)
        case item
          when Libis::Ingester::Collection
            export_collection(item)
          when Libis::Ingester::IntellectualEntity
            export_item(item)
            stop_processing_subitems
          else
            # do nothing
        end
      end

      private

      # @param [Libis::Ingester::IntellectualEntity] item
      def export_item(item)
        pid = item.pid
        unless pid
          warn "Object #{item.name} was not ingested fully.", item
          return
        end

        export_file = get_export_file(item)

        key = get_key(export_file, item)

        write_export(export_file, key, pid)

        debug 'Item %s with pid %s exported.', key, pid

      end

      # @param [Libis::Ingester::Collection] item
      def export_collection(item)
        pid = item.properties['collection_id']
        unless pid
          warn "Collection #{item.name} was not found/created.", item
          return
        end

        export_file = get_export_file(item)

        key = get_key(export_file, item)

        pid = "col#{pid}"
        write_export(export_file, key, pid)

        debug 'Collection %s with pid %s exported.', key, pid

      end

      def get_key(export_file, item)
        run_item = item.get_run
        unless run_item.nil? || run_item.properties['export_file']
          run_item.properties['export_file'] = export_file
          run_item.save!
        end
        eval(parameter(:export_key))
      end

      def get_export_file(item)
        FileUtils.mkdir_p(parameter(:export_dir))
        File.join(parameter(:export_dir), "#{item.get_run.name}.#{parameter(:export_format)}")
      end

      def write_export(export_file, key_value, pid)
        open(export_file, 'a') do |f|
          case parameter(:export_format).to_sym
            when :tsv
              f.puts "KEY\tPID\tURL" if f.size == 0 && parameter(:export_header)
              f.puts "#{for_tsv(key_value)}\t#{for_tsv(pid)}" +
                         "\t#{for_tsv("http://resolver.libis.be/#{pid}/representation")}"
            when :csv
              f.puts 'KEY,PID,URL' if f.size == 0 && parameter(:export_header)
              f.puts "#{for_csv(key_value)},#{for_csv(pid)}" +
                         ",#{for_csv("http://resolver.libis.be/#{pid}/representation")}"
            when :xml
              f.puts '<?xml version="1.0" encoding="UTF-8"?>' if f.size == 0 && parameter(:export_header)
              f.puts '<item' +
                         " key=\"#{for_xml(key_value)}\"" +
                         " pid=\"#{for_xml(pid)}\"" +
                         " url=\"#{for_xml("http://resolver.libis.be/#{pid}/representation")}\"" +
                         ' />'
            when :yml
              f.puts '# Ingester export file' if f.size == 0 && parameter(:export_header)
              f.puts "- key: #{for_yml(key_value)}" +
                         "\n  value: #{for_yml(pid)}" +
                         "\n  url: #{for_yml("http://resolver.libis.be/#{pid}/representation")}"
            else
              #nothing
          end

        end
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
