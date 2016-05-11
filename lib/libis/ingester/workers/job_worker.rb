require 'libis-ingester'
require 'libis/tools/extend/hash'
require 'sidekiq'

module Libis
  module Ingester

    class JobWorker
      include Sidekiq::Worker

      def perform(job_id, options = {})
        job = ::Libis::Ingester::Job.find_by(id: job_id)
        raise RuntimeError.new "Workflow #{job_id} not found" unless job.is_a? ::Libis::Ingester::Job
        job.execute options.key_symbols_to_strings(recursive: true)
      end

      def self.subject(job_id)
        ::Libis::Ingester::Job.find_by(id: job_id)
      end

    end

  end
end

