require 'grape'

require 'libis/ingester/job'
require 'libis/ingester/organization'

module Libis::Ingester::API
  class Jobs < Grape::API

    resource :jobs do
      desc 'get list of jobs'
      params do
        optional :organization, type: String, desc: 'Organization ID'
      end
      get '' do
        if declared(params).organization
          org = Libis::Ingester::Organization.find_by(id: declared(params).organization)
          org.jobs
        else
          render Libis::Ingester::Job.all
        end

      end
    end

  end
end