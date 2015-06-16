# encoding: utf-8

require 'libis/workflow/mongoid'

require_relative 'metadata_record'
require_relative 'access_right'
require_relative 'representation'

module Libis
  module Ingester

    class Item
      include ::Libis::Workflow::Mongoid::WorkItem

      storage_options[:collection] = 'ingest_items'
      run_class 'Libis::Ingester::Run'

      embeds_one :metadata, class_name: 'Libis::Ingester::MetadataRecord', inverse_of: :item
      has_one :access_right, class_name: 'Libis::Ingester::AccessRight', inverse_of: nil

      def name=(value)
        self.properties[:name] = value
      end

      def label
        File.basename(self.name, '.*')
      end

    end

  end
end
