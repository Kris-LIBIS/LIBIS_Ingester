# encoding: utf-8
require 'libis/workflow/mongoid'

module Libis
  module Ingester

    class Workflow
      include Libis::Workflow::Mongoid::Workflow

      store_in collection: 'ingest_flows'

      has_many :jobs, inverse_of: :workflow, class_name: ::Libis::Ingester::Job.to_s

      def workflow_runs
        # noinspection RubyResolve
        self.jobs.map {|job| job.runs.all }.flatten
      end

    end

  end
end
