require 'libis-ingester'
require 'libis/tools/extend/hash'
require 'sidekiq'

module Libis
  module Ingester

    class RunWorker
      include Sidekiq::Worker

      sidekiq_options queue: :default

      def perform(run_id, options = {})
        run = ::Libis::Ingester::Run.find_by(id: run_id)
        raise RuntimeError.new "Run #{run_id} not found" unless run.is_a? ::Libis::Ingester::Run
        run.execute options.key_symbols_to_strings(recursive: true)
      end

      def self.push_retry_job(run_id, queue)
        client_push('class' => self, 'queue' => queue, 'retry' => false, 'args' => [run_id, action: :retry])
      end

      def self.push_restart_job(run_id, queue)
        client_push('class' => self, 'queue' => queue, 'retry' => false, 'args' => [run_id, action: :restart])
      end

      def self.subject(run_id)
        ::Libis::Ingester::Run.find_by(id: run_id)
      end

    end

  end
end
