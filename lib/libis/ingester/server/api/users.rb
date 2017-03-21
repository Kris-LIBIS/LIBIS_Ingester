require 'libis/ingester/run'
require 'libis/ingester/server/api/representer/run'

module Libis::Ingester::API
  class Runs < Grape::API
    include Grape::Kaminari

    namespace :runs do

      desc 'get list of runs' do
        success Representer::RunRepresenter
      end
      paginate per_page: 2, max_per_page: 10
      params do
        optional :fields, type: Hash, desc: 'Field selection as comma-separated list in a Hash with item type as key.'
      end
      get '' do
        runs = paginate(Libis::Ingester::Run.all)
        Representer::RunRepresenter.for_collection.prepare(runs).
            # extend(Representable::Debug).
            to_hash(pagination_hash(runs)
            # .merge(fields_opts(declared(params).fields, {jobs: [:name, :description]}))
            )
      end

      desc 'create run' do
        success Representer::RunRepresenter
      end
      params do
        requires :data, type: Representer::RunRepresenter, desc: 'Run info'
      end
      post do
        run = Libis::Ingester::Run.new
        Representer::RunRepresenter.prepare(run).from_hash(declared(params))
        run.save!
        Representer::RunRepresenter.prepare(run).to_json(item_hash(run))
      end

      route_param :id do
        params do
          requires :id, type: String, desc: 'Run ID', allow_blank: false
        end

        namespace do

          desc 'get run information' do
            success Representer::RunRepresenter
          end
          params do
            optional :fields, type: Hash, desc: 'Field selection as comma-separated list in a Hash with item type as key.'
          end
          get do
            run = Libis::Ingester::Run.find(declared(params).id)
            Representer::RunRepresenter.prepare(run).
                to_hash(item_hash(run)
                # .merge(fields_opts(declared(params).fields, {jobs: nil}))
                )
          end

          desc 'update run information' do
            success Representer::RunRepresenter
          end
          params do
            requires :data, type: Representer::RunRepresenter, desc: 'Run info'
          end
          put do
            run = Libis::Ingester::Run.find(declared(params).id)
            Representer::RunRepresenter.new(run).from_hash(declared(params))
            run.save!
            Representer::RunRepresenter.new(run).to_hash(item_hash(run))
          end

        end

      end

    end

  end
end