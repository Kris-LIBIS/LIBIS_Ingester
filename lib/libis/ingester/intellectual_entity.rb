# encoding: utf-8

require 'libis/ingester'
require 'libis/tools/extend/hash'

module Libis
  module Ingester

    class IntellectualEntity < Libis::Ingester::Item
      include Libis::Workflow::Mongoid::Base

      field :ingest_type, type: String, default: 'METS'
      field :pid, type: String

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
        self.items.reject { |item| item.is_a? ::Libis::Ingester::Representation }
      end

      # noinspection RubyResolve
      def info
        result = super
        result[:retention_period_id] = self.retention_period.rp_id if self.retention_period
        result
      end

    end

  end
end
