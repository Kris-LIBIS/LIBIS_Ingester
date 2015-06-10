# encoding: utf-8
require 'libis/workflow/mongoid'

module Libis
  module Ingester

    class Flow
      include Libis::Workflow::Mongoid::Workflow

      storage_options[:collection] = 'ingest_flows'
      run_class 'Libis::Ingester::Run'

    end

  end
end
