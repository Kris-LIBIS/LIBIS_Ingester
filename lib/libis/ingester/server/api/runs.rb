require 'libis/ingester/job'

module Libis::Ingester::API
  class Runs < Grape::API
    include Grape::Kaminari

    REPRESENTER = Representer::Run
    DB_CLASS = Libis::Ingester::Run

    namespace :runs do

      helpers ParamHelper
      helpers StatusHelper
      helpers RepresentHelper
      helpers ObjectHelper

      desc 'get list of runs' do
        success REPRESENTER
      end
      paginate per_page: 10, max_per_page: 50
      params do
        use :run_fields
      end
      get '' do
        guard do
          present_collection(collection: paginate(Kaminari.paginate_array(DB_CLASS.all)), representer: REPRESENTER, with_pagination: true)
        end
      end

      params do
        requires :run_id, type: String, desc: 'run ID', allow_blank: false, run_id: true
      end
      route_param :run_id do

        desc 'get run information' do
          success REPRESENTER
        end
        params do
          use :run_fields
        end
        get do
          present_item(representer: REPRESENTER, item: current_run)
        end

        desc 'update run information' do
          success REPRESENTER
        end
        params do
          requires :data, type: REPRESENTER, desc: 'run info'
        end
        put do
          guard do
            _run = current_run
            parse_item(representer: REPRESENTER, item: _run)
            _run.save!
            present_item(representer: REPRESENTER, item: current_run)
          end
        end

        desc 'delete run'
        delete do
          guard do
            current_run.destroy
            api_success("run (#{declared(params)[:run_id]}) deleted")
          end
        end

        REPRESENTER_1 = Representer::Item

        desc 'get run items' do
          success REPRESENTER_1
        end
        paginate per_page: 10, max_per_page: 50
        params do
          use :item_fields
        end
        get 'items' do
          present_collection(
              representer: REPRESENTER_1,
              collection: paginate(Kaminari.paginate_array(current_run.items)),
              with_pagination: true
          )
        end

      end # route_param :run_id

    end # namespace :runs

  end # Class

end # Module