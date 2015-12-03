# encoding: utf-8
require 'libis/workflow/task'

module Libis
  module Ingester
    class Task < ::Libis::Workflow::Task

      parameter item_types: nil, datatype: Array,
                description: 'Items types to process.'

      protected

      def pre_process(item)
        skip_processing_item unless parameter(:item_types).blank? ||
            parameter(:item_types).any? { |klass| item.is_a?(klass.to_s.constantize) }
      end

    end
  end
end
