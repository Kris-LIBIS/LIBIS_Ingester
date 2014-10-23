# encoding: utf-8
require 'LIBIS_Workflow'

require 'libis/ingester/item'

module LIBIS
  module Ingester

    class IngestBuilder < LIBIS::Workflow::Task

      def process(item)

        case item
          when LIBIS::Ingester::Run
            item.items.each { |i| process(i) }
          when LIBIS::Ingester::Item
            if item.properties[:ingest_type]
              create_ingest(item)
            else
              item.items.each { |i| process(i) }
            end
          else
            # do nothing
        end

      end

      def create_ingest(item)

      end

    end

  end
end
