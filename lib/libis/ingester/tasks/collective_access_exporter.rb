require 'fileutils'

require 'libis/tools/xml_document'

require 'libis-ingester'
require 'libis/ingester/ftps_service'

module Libis
  module Ingester

    class CollectiveAccessExporter < ::Libis::Ingester::Task

      parameter export_dir: '.', description: 'Directory where the export files will be copied'
      parameter item_types: ['Libis::Ingester::IntellectualEntity']
      parameter recursive: true, frozen: true

      protected

      def process(item)
        export_item(item)
        stop_processing_subitems
      end

      private

      # @param [Libis::Ingester::IntellectualEntity] item
      def export_item(item)
        identifier = item.properties['identifier']
        unless item.pid
          warn "Object #{identifier} was not ingested fully."
          return
        end

        FileUtils.mkdir_p(parameter(:export_dir))
        export_file = File.join(parameter(:export_dir), "#{item.get_run.name}.csv")
        open(export_file, 'a') do |f|
          f.puts "#{item.label}\t#{item.pid}"
        end

        info 'Item %s with pid %s exported.', item.label, item.pid

      end

    end
  end
end
