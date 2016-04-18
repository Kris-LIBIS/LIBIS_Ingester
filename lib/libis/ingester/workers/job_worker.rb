require 'libis-ingester'
require 'libis/tools/extend/hash'
require 'sidekiq'

module Libis
  module Ingester

    class JobWorker
      include Sidekiq::Worker
      sidekiq_options queue: :ingester, :retry => false

      def perform(job_id, options = {})
        job = ::Libis::Ingester::Job.find_by(job_id)
        raise RuntimeError.new "Workflow #{job_id} not found" unless job.is_a? ::Libis::Ingester::Job
        job.execute options.key_symbols_to_strings(recursive: true)
      end

    end

  end
end

