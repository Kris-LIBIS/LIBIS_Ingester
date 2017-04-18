require 'libis/ingester/job'
require 'libis/ingester/server/api/representer/job'
require 'representable/debug'

module Libis::Ingester::API
  class Jobs < Grape::API
    include Grape::Kaminari

    namespace :jobs do

      desc 'get list of jobs' do
        success Representer::JobRepresenter
      end
      paginate per_page: 2, max_per_page: 10
      params do
        optional :fields, type: Hash, desc: 'Field selection as comma-separated list in a Hash with item type as key.'
      end
      get '' do
        jobs = paginate(Libis::Ingester::Job.all)
        Representer::JobRepresenter.for_collection.prepare(jobs).
            # extend(Representable::Debug).
            to_hash(pagination_hash(jobs)
            # .merge(fields_opts(declared(params).fields, {jobs: [:name, :description]}))
            )
      end

      desc 'create job' do
        success Representer::JobRepresenter
      end
      params do
        requires :data, type: Representer::JobRepresenter, desc: 'Job info'
      end
      post do
        job = Libis::Ingester::Job.new
        Representer::JobRepresenter.prepare(job).from_hash(declared(params))
        job.save!
        Representer::JobRepresenter.prepare(job).to_json(item_hash(job))
      end

      route_param :id do
        params do
          requires :id, type: String, desc: 'Job ID', allow_blank: false
        end

        namespace do

          desc 'get job information' do
            success Representer::JobRepresenter
          end
          params do
            optional :fields, type: Hash, desc: 'Field selection as comma-separated list in a Hash with item type as key.'
          end
          get do
            job = Libis::Ingester::Job.find(declared(params).id)
            Representer::JobRepresenter.prepare(job).
                to_hash(item_hash(job)
                # .merge(fields_opts(declared(params).fields, {jobs: nil}))
                )
          end

          desc 'update job information' do
            success Representer::JobRepresenter
          end
          params do
            requires :data, type: Representer::JobRepresenter, desc: 'Job info'
          end
          put do
            job = Libis::Ingester::Job.find(declared(params).id)
            Representer::JobRepresenter.new(job).from_hash(declared(params))
            job.save!
            Representer::JobRepresenter.new(job).to_hash(item_hash(job))
          end

        end

      end

    end

  end
end