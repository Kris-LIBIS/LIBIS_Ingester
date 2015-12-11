require 'libis-ingester'

module Libis
  module Ingester

    class RunWorker

      def perform(run_id, options = {})
        run = ::Libis::Ingester::Run.find_by(id: run_id).first
        raise RuntimeError.new "Run #{run_id} not found" unless run.is_a? ::Libis::Ingester::Run
        run.execute options
      end

    end

  end
end
