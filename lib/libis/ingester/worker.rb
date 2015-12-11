require 'libis/workflow/mongoid/worker'

module Libis
  module Ingester

    class Worker < Libis::Workflow::Mongoid::Worker

      def get_job(job_config)
        job_name = job_config.delete(:name)
        job = ::Libis::Ingester::Job.find(name: job_name).first
        raise RuntimeError.new "Workflow #{job_name} not found" unless job.is_a? ::Libis::Ingester::Job
        job
      end

    end

  end
end
