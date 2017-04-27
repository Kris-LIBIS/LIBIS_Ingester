require 'libis/ingester/ingest_model'

module Libis::Ingester::API
  class IngestModels < Grape::API
    include Grape::Kaminari

    REPRESENTER = Representer::IngestModel
    DB_CLASS = Libis::Ingester::IngestModel

    namespace :ingest_models do

      helpers ParamHelper
      helpers StatusHelper
      helpers RepresentHelper
      helpers ObjectHelper

      desc 'get list of ingest models' do
        success REPRESENTER
      end
      paginate per_page: 10, max_per_page: 50
      params do
        use :ingest_model_fields
      end
      get '' do
        guard do
          present_collection(collection: paginate(DB_CLASS), representer: REPRESENTER, with_pagination: true)
        end
      end

      desc 'create ingest model' do
        success REPRESENTER
      end
      params do
        requires :data, type: REPRESENTER, desc: 'ingest model info'
      end
      post do
        guard do
          _ingest_model = DB_CLASS.new
          _ingest_model = parse_item(item: _ingest_model, representer: REPRESENTER)
          _ingest_model.save!
          present_item(item: _ingest_model, representer: REPRESENTER)
        end
      end

      params do
        requires :ingest_model_id, type: String, desc: 'ingest model ID', allow_blank: false, ingest_model_id: true
      end
      route_param :ingest_model_id do

        desc 'get ingest model information' do
          success REPRESENTER
        end
        params do
          use :ingest_model_fields
        end
        get do
          present_item(representer: REPRESENTER, item: current_ingest_model)
        end

        desc 'update ingest model information' do
          success REPRESENTER
        end
        params do
          requires :data, type: REPRESENTER, desc: 'ingest model info'
        end
        put do
          guard do
            _ingest_model = current_ingest_model
            parse_item(representer: REPRESENTER, item: _ingest_model)
            _ingest_model.save!
            present_item(representer: REPRESENTER, item: current_ingest_model)
          end
        end

        desc 'delete ingest model'
        delete do
          guard do
            current_ingest_model.destroy
            api_success("ingest model (#{declared(params)[:ingest_model_id]}) deleted")
          end
        end

        desc 'set ingest model'
        params do
          requires :ingest_model_id, type: String, desc: 'ingest model ID', ingest_model_id: true
        end
        put 'ingest_model' do
          guard do
            _ingest_model = current_ingest_model
            _ingest_model = ingest_model
            # noinspection RubyResolve
            _ingest_model.ingest_model = _ingest_model
            _ingest_model.save!
            api_success("ingest model '#{_ingest_model.name}' (#{_ingest_model.id}) ingest model set to '#{_ingest_model.name}' (#{_ingest_model.id})")
          end
        end

        desc 'set organization'
        params do
          requires :organization_id, type: String, desc: 'organization ID', organization_id: true
        end
        put 'organization' do
          guard do
            _ingest_model = current_ingest_model
            _organization = organization
            # noinspection RubyResolve
            _ingest_model.organization = _organization
            _ingest_model.save!
            api_success("ingest model '#{_ingest_model.name}' (#{_ingest_model.id}) organization set to '#{_organization.name}' (#{_organization.id})")
          end
        end

        desc 'set workflow'
        params do
          requires :workflow_id, type: String, desc: 'workflow ID', workflow_id: true
        end
        put 'workflow' do
          guard do
            _ingest_model = current_ingest_model
            _workflow = workflow
            # noinspection RubyResolve
            _ingest_model.workflow = _workflow
            _ingest_model.save!
            api_success("ingest model '#{_ingest_model.name}' (#{_ingest_model.id}) workflow set to '#{_workflow.name}' (#{_workflow.id})")
          end
        end


        namespace :runs do

          REPRESENTER_1 = Representer::Run

          desc 'get ingest model runs' do
            success REPRESENTER_1
          end
          params do
            use :run_fields
          end
          get '' do
            guard do
              present_collection(representer: REPRESENTER_1, collection: current_ingest_model.runs)
            end
          end

          desc 'submit a new ingest model run' do
            success REPRESENTER_1
          end
          params do
            use :run_fields
          end
          post '' do
            guard do
              # submit ingest model
              # - create run object
              # - add run to the queue
              # - return new run object
              # required input:
              # - queue (or select automatically?)
              # - input parameters
            end
          end

        end # namespace :runs

      end # route_param :ingest_model_id

    end # namespace :ingest_models

  end # Class

end # Module