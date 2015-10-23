# encoding: utf-8
require 'libis/workflow/mongoid'

module Libis
  module Ingester

    class Workflow
      include Libis::Workflow::Mongoid::Workflow

      store_in collection: 'ingest_flows'
      run_class Libis::Ingester::Run.to_s

      has_one :ingest_model, class_name: ::Libis::Ingester::IngestModel.to_s

    end

  end
end
