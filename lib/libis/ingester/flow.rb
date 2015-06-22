# encoding: utf-8
require 'libis/workflow/mongoid'

module Libis
  module Ingester

    class Flow
      include Libis::Workflow::Mongoid::Workflow

      store_in collection: 'ingest_flows'
      run_class Libis::Ingester::Run.to_s

    end

  end
end
