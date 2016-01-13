require 'libis-ingester'
require 'sidekiq'

module Libis
  module Ingester

    class RunWorker
      include Sidekiq::Worker
      sidekiq_options queue: :ingester, :retry => false

      def perform(run_id, options = {})
        run = ::Libis::Ingester::Run.find_by(id: run_id)
        raise RuntimeError.new "Run #{run_id} not found" unless run.is_a? ::Libis::Ingester::Run
        run.execute options
      end

    end

  end
end
