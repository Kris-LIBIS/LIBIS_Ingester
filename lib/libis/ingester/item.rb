# encoding: utf-8

require 'libis/workflow/mongoid'

module Libis
  module Ingester

    class Item < ::Libis::Workflow::Mongoid::WorkItem

      embeds_one :metadata_record, class_name: Libis::Ingester::MetadataRecord.to_s, inverse_of: :item
      belongs_to :access_right, class_name: Libis::Ingester::AccessRight.to_s, inverse_of: nil

      accepts_nested_attributes_for :metadata_record, :access_right

      def name=(value)
        self.properties['name'] = value
      end

      def label
        self.properties['label'] || self.name
      end

      def label=(value)
        self.properties['label'] = value
      end

      def labels
        (self.parent.labels rescue Array.new).push(label).compact
      end

      def labelpath;
        self.labels.join('/');
      end

      def ancestors
        item, item_list = self, []
        while (parent = item.parent) && parent.is_a?(::Libis::Ingester::Item)
          item_list << parent
          item = parent
        end
        item_list
      end

      def to_hash
        result = super
        # noinspection RubyResolve
        result[:access_right_id] = self.access_right.ar_id if self.access_right
        result[:metadata_record] = self.metadata_record.to_hash if self.metadata_record
        result.cleanup
      end


    end

  end
end
