# encoding: utf-8
require 'libis/workflow/mongoid'

module Libis
  module Ingester

    class Workflow < Libis::Workflow::Mongoid::Workflow

      def workflow_runs
        # noinspection RubyResolve
        self.jobs.map {|job| job.runs.all }.flatten
      end

    end

  end
end
