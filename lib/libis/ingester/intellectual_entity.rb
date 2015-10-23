# encoding: utf-8

require 'libis/ingester'

module Libis
  module Ingester

    class IntellectualEntity < Libis::Ingester::Item
      include Libis::Workflow::Mongoid::Base

      field :ingest_type, type: String, default: 'METS'
      field :status
      field :entity_type
      field :user_a
      field :user_b
      field :user_c

      belongs_to :access_right, class_name: Libis::Ingester::AccessRight.to_s, inverse_of: nil
      belongs_to :retention_period, class_name: Libis::Ingester::RetentionPeriod.to_s, inverse_of: nil

      def representations
        self.items.select { |item| item.is_a? ::Libis::Ingester::Representation }
      end

      def representation(name_or_id)
        representations.each do |representation|
          return representation if name_or_id == representation.id or name_or_id == representation.name
        end
        nil
      end

      def originals
        self.items.select { |item| !(item.is_a? ::Libis::Ingester::Representation) }
      end

    end

  end
end
