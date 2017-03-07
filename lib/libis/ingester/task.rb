# encoding: utf-8
require 'libis/workflow/task'
require 'libis-ingester'

require 'libis/tools/extend/string'

module Libis
  module Ingester
    class Task < ::Libis::Workflow::Task

      parameter item_types: nil, datatype: Array,
                description: 'Item types to process.'

      def self.taskgroup(name = nil)
        @taskgroup = name if name
        @taskgroup || superclass.group rescue nil
      end

      def self.description(text = nil)
        @description ||= (text || '')
        @description
      end

      def self.help(text = nil)
        @helptext ||= (text || '')
        @helptext
      end

      def run(item)
        new_item = super(item)
        item = new_item if new_item.is_a?(Libis::Workflow::WorkItem)
        item.reload
        item.reload_relations
        item
      end

      protected

      def pre_process(item)
        skip_processing_item unless parameter(:item_types).blank? ||
            parameter(:item_types).any? { |klass| item.is_a?(klass.to_s.constantize) }
      end

    end
  end
end
