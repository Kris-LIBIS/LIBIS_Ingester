require 'libis-ingester'
require 'sidekiq'

module Libis
  module Ingester

    class JobWorker
      include Sidekiq::Worker
      sidekiq_options queue: :ingester, :retry => false

      def perform(job_id, options = {})
        job = ::Libis::Ingester::Job.find_by(id: job_id)
        raise RuntimeError.new "Workflow #{job_id} not found" unless job.is_a? ::Libis::Ingester::Job
        job.execute options
      end

    end

  end
end

