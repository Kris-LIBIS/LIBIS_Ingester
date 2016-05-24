# encoding: utf-8
require 'libis/workflow/task'

module Libis
  module Ingester
    class Task < ::Libis::Workflow::Task

      parameter item_types: nil, datatype: Array,
                description: 'Item types to process.'

      protected

      def pre_process(item)
        skip_processing_item unless parameter(:item_types).blank? ||
            parameter(:item_types).any? { |klass| item.is_a?(klass.to_s.constantize) }
      end

      def status_counter(item)
        @counter ||= 0
        @counter += 1
        item.get_run.status_progress(self.namepath, @counter)
      end

    end
  end
end
