# encoding: utf-8

require 'libis/workflow/mongoid'

module Libis
  module Ingester

    class Item < ::Libis::Workflow::Mongoid::WorkItem

      embeds_one :metadata_record, class_name: Libis::Ingester::MetadataRecord.to_s, inverse_of: :item
      has_one :access_right, class_name: Libis::Ingester::AccessRight.to_s, inverse_of: nil

      accepts_nested_attributes_for :metadata_record, :access_right

      def name=(value)
        self.properties[:name] = value
      end

      def label
        File.basename(self.name, '.*')
      end

      def ancestors
        item, item_list = self, []
        while(parent = item.parent)
          item_list << parent
          item = parent
        end
        item_list
      end

      def uplevel
        self.parent || self.run
      end

    end

  end
end
