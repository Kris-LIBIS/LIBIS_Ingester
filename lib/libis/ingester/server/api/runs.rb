require 'libis/ingester/run'
require 'libis/ingester/server/api/representer/run'

module Libis::Ingester::API
  class Runs < Grape::API
    include Grape::Kaminari

    namespace :runs do

      desc 'get list of runs' do
        success Representer::Run
      end
      paginate per_page: 2, max_per_page: 10
      params do
        optional :fields, type: Hash, desc: 'Field selection as comma-separated list in a Hash with item type as key.'
      end
      get '' do
        runs = paginate(Libis::Ingester::Run.all)
        Representer::Run.for_collection.prepare(runs).
            # extend(Representable::Debug).
            to_hash(pagination_hash(runs)
            # .merge(fields_opts(declared(params).fields, {jobs: [:name, :description]}))
            )
      end

      desc 'create run' do
        success Representer::Run
      end
      params do
        requires :data, type: Representer::Run, desc: 'Run info'
      end
      post do
        run = Libis::Ingester::Run.new
        Representer::Run.prepare(run).from_hash(declared(params))
        run.save!
        Representer::Run.prepare(run).to_json(item_hash(run))
      end

      route_param :id do
        params do
          requires :id, type: String, desc: 'Run ID', allow_blank: false
        end

        namespace do

          desc 'get run information' do
            success Representer::Run
          end
          params do
            optional :fields, type: Hash, desc: 'Field selection as comma-separated list in a Hash with item type as key.'
          end
          get do
            run = Libis::Ingester::Run.find(declared(params).id)
            Representer::Run.prepare(run).
                to_hash(item_hash(run)
                # .merge(fields_opts(declared(params).fields, {jobs: nil}))
                )
          end

          desc 'update run information' do
            success Representer::Run
          end
          params do
            requires :data, type: Representer::Run, desc: 'Run info'
          end
          put do
            run = Libis::Ingester::Run.find(declared(params).id)
            Representer::Run.new(run).from_hash(declared(params))
            run.save!
            Representer::Run.new(run).to_hash(item_hash(run))
          end

        end

      end

    end

  end
end