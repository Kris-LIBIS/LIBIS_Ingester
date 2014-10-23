# encoding: utf-8

require 'LIBIS_Workflow_Mongoid'

require_relative 'metadata_record'
require_relative 'access_right'
require_relative 'manifestation'

module LIBIS
  module Ingester

    class Item
      include ::LIBIS::Workflow::Mongoid::WorkItem

      storage_options[:collection] = 'ingest_items'
      run_class 'LIBIS::Ingester::Run'

      embeds_one :metadata, class_name: 'LIBIS::Ingester::MetadataRecord', inverse_of: :item

      has_one :access_right, class_name: 'LIBIS::Ingester::AccessRight', inverse_of: nil
      has_one :manifestation, class_name: 'LIBIS::Ingester::Manifestation', inverse_of: nil

      def name=(value)
        self.properties[:name] = value
      end

      def label
        File.basename(self.name, '.*')
      end

    end

  end
end
