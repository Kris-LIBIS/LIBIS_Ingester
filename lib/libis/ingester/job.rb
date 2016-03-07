# encoding: utf-8
require 'libis/workflow/mongoid/job'

require 'libis/ingester'

module Libis
  module Ingester

    class Job < Libis::Workflow::Mongoid::Job

      field :schedule

      belongs_to :organization, class_name: Libis::Ingester::Organization.to_s, inverse_of: :jobs
      belongs_to :ingest_model, class_name: Libis::Ingester::IngestModel.to_s, inverse_of: :jobs

      # noinspection RubyResolve
      def producer
        self.organization.producer
      end

      def material_flow
        self.organization.material_flow
      end

      def ingest_dir
        self.organization.ingest_dir
      end

      # noinspection RubyResolve
      def create_run_object
        self.run_object = 'Libis::Ingester::Run'
        run = super
        run.ingest_model = self.ingest_model
        run
      end

    end

  end
end
