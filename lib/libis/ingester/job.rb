# encoding: utf-8
require 'libis/workflow/mongoid/job'

require 'libis/ingester'

module Libis
  module Ingester

    class Job < Libis::Workflow::Mongoid::Job

      field :schedule
      field :material_flow

      field :error_to, type: String
      field :success_to, type: String

      # noinspection RailsParamDefResolve
      belongs_to :organization, class_name: Libis::Ingester::Organization.to_s, inverse_of: :jobs
      # noinspection RailsParamDefResolve
      belongs_to :ingest_model, class_name: Libis::Ingester::IngestModel.to_s, inverse_of: :jobs

      index({organization_id: 1, name: 1}, {name: 'by_organization'})
      index({ingest_model_id: 1, name: 1}, {name: 'by_ingest_model'})

      def self.from_hash(hash)
        hash['log_level'] ||= 'DEBUG'
        # noinspection RubyResolve
        self.create_from_hash(hash, [:name]) do |item, cfg|
          item.workflow = Libis::Ingester::Workflow.from_hash(name: cfg.delete('workflow'))
          item.organization = Libis::Ingester::Organization.from_hash(name: cfg.delete('organization'))
          item.ingest_model = Libis::Ingester::IngestModel.from_hash(name: cfg.delete('ingest_model'))
        end
      end

      # noinspection RubyResolve
      def producer
        self.organization.producer
      end

      def material_flow
        self.organization.material_flow[self.read_attribute(:material_flow) || 'default']
      end

      def ingest_dir
        self.organization.ingest_dir
      end

      # noinspection RubyResolve
      def create_run_object
        self.run_object = 'Libis::Ingester::Run'
        super
      end

      def execute(opts = {})
        opts['run_config'] ||= {}
        opts['run_config']['error_to'] = self.error_to if self.error_to
        opts['run_config']['success_to'] = self.success_to if self.success_to
        super opts
      end

    end

  end
end
