# encoding: utf-8

require 'LIBIS_Workflow_Mongoid'

module LIBIS
  module Ingester

    class Run
      include ::LIBIS::Workflow::Mongoid::Run

      storage_options[:collection] = 'ingest_runs'
      workflow_class 'LIBIS::Ingester::Flow'
      item_class 'LIBIS::Ingester::Item'

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
