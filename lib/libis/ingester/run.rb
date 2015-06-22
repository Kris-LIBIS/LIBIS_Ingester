# encoding: utf-8

require 'libis/ingester'

module Libis
  module Ingester

    class Run
      include ::Libis::Workflow::Mongoid::Run

      store_in collection: 'ingest_runs'
      workflow_class Libis::Ingester::Flow.to_s
      item_class Libis::Ingester::Item.to_s

      has_one :ingest_model, class_name: ::Libis::Ingester::IngestModel.to_s

      def name
        self.workflow.name + self.start_date.strftime('_%Y%m%dT%H%M%S')
      end

      def info
        {
            class: 'Run',
            name: self.name,
            items: self.items.map {|item| item.info},
            options: self.options,
            properties: self.properties,
            start_date: self.start_date,

        }
      end
    end

  end
end
