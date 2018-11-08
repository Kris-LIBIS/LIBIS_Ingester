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

      belongs_to :ingest_model, class_name: Libis::Ingester::IngestModel.to_s, inverse_of: nil
      belongs_to :access_right, class_name: Libis::Ingester::AccessRight.to_s, inverse_of: nil
      belongs_to :retention_period, class_name: Libis::Ingester::RetentionPeriod.to_s, inverse_of: nil

      def representations
        self.items.where(_type: Libis::Ingester::Representation.to_s).no_timeout
      end

      def representation(name_or_id)
        self.representations.where(id: name_or_id).first || self.representations.where(name: name_or_id).first
      end

      def originals
        self.items.ne(_type: Libis::Ingester::Representation.to_s).no_timeout
      end

      # @return [Libis::Ingester::IngestModel]
      def get_ingest_model
        self.ingest_model || self.get_run.get_ingest_model
      end

      # @return [Libis::Ingester::AccessRight]
      def get_access_right
        # noinspection RubyResolve
        self.access_right || self.get_run.get_access_right
      end

      # @return [Libis::Ingester::RetentionPeriod]
      def get_retention_period
        # noinspection RubyResolve
        self.retention_period || self.get_run.get_retention_period
      end

      def set_ingest_model(ingest_model_name)
        return self.ingest_model = nil if ingest_model_name.nil?
        im = Libis::Ingester::IngestModel.find_by(name: ingest_model_name)
        raise WorkflowError, "Ingest Model '#{ingest_model_name}' not found in the ingester database." unless im
        self.ingest_model = im
      end

      def set_access_rigth(access_right_name)
        return self.access_right = nil if access_right_name.nil?
        ar = Libis::Ingester::AccessRight.find_by(name: access_right_name)
        raise WorkflowError, "Access Right'#{access_right_name}' not found in the ingester database." unless ar
        self.access_right = ar
      end

      # noinspection RubyParameterNamingConvention
      def set_retention_period(retention_period_name)
        return self.retention_period = nil if retention_period_name.nil?
        rp = Libis::Ingester::RetentionPeriod.find_by(name: retention_period_name)
        raise WorkflowError, "Retention Period '#{retention_period_name}' not found in the ingester database." unless rp
        self.retention_period = rp
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
