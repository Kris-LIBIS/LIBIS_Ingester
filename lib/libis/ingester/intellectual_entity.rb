# encoding: utf-8

require 'libis/ingester'
require 'libis/tools/extend/hash'

module Libis
  module Ingester

    class IntellectualEntity < Libis::Ingester::Item
      include Libis::Workflow::Mongoid::Base

      field :ingest_type, type: String, default: 'METS'
      field :pid, type: String

      index({pid: 1}, {sparse: true, name: 'by_pid'})

      belongs_to :retention_period, class_name: Libis::Ingester::RetentionPeriod.to_s, inverse_of: nil, optional: true

      def representations
        self.items.where(_type: Libis::Ingester::Representation.to_s).no_timeout
      end

      def representation(name_or_id)
        self.representations.where(id: name_or_id).first || self.representations.where(name: name_or_id).first
      end

      def originals
        self.items.ne(_type: Libis::Ingester::Representation.to_s).no_timeout
      end

      # noinspection RubyResolve
      def to_hash
        result = super
        result[:retention_period_id] = self.retention_period.rp_id if self.retention_period
        result.cleanup
      end

    end

  end
end
