require 'libis-ingester'

module Libis
  module Ingester

    class JobWorker

      def perform(job_id, options = {})
        job = ::Libis::Ingester::Job.find_by(id: job_id).first
        raise RuntimeError.new "Workflow #{job_id} not found" unless job.is_a? ::Libis::Ingester::Job
        job.execute options
      end

    end

  end
end

