module Libis
  module Ingester
    autoload :JobWorker, 'libis/ingester/workers/job_worker'
    autoload :RunWorker, 'libis/ingester/workers/run_worker'
  end
end