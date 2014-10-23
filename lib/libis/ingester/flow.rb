# encoding: utf-8
require 'LIBIS_Workflow_Mongoid'
module LIBIS
  module Ingester

    class Flow
      include LIBIS::Workflow::Mongoid::Workflow

      storage_options[:collection] = 'ingest_flows'
      run_class 'LIBIS::Ingester::Run'

    end

  end
end
