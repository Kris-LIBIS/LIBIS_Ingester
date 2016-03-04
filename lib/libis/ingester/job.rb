# encoding: utf-8
require 'libis/workflow/mongoid/job'

require 'libis/ingester'

module Libis
  module Ingester

    class Job < Libis::Workflow::Mongoid::Job

      field :schedule
      field :log_path, type: String
      field :log_count, type: Integer
      field :log_rotate, type: String, default: 'daily'
      field :log_max_size, type: Integer
      field :log_level, type: Integer, default: 0

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

      def logger
        @logger ||=
            self.log_path ?
            begin
              logger = ::Logger.new(
                  File.join(self.log_path, "#{self.name}.log"),
                  (self.log_count || self.log_rotate),
                  (self.log_max_size || 1024 ** 2)
              )
              logger.formatter = ::Logger::Formatter.new
              logger.level = self.log_level
              logger
            end : nil

      end

      # noinspection RubyResolve
      def create_run_object
        self.run_object = 'Libis::Ingester::Run'
        run = super
        if self.jid
          run.properties['job_id'] = self.jid
          Libis::Ingester::Config.lo
        end
        run.ingest_model = self.ingest_model
        run
      end

    end

  end
end
