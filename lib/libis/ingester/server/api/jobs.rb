require 'libis/ingester/job'

module Libis::Ingester::API
  class Jobs < Grape::API
    include Grape::Kaminari

    REPRESENTER = Representer::Job
    DB_CLASS = Libis::Ingester::Job

    namespace :jobs do

      helpers ParamHelper
      helpers StatusHelper
      helpers RepresentHelper
      helpers ObjectHelper

      desc 'get list of jobs' do
        success REPRESENTER
      end
      paginate per_page: 10, max_per_page: 50
      params do
        use :field_selector
      end
      get '' do
        guard do
          present_collection(collection: paginate(DB_CLASS), representer: REPRESENTER, with_pagination: true)
        end
      end

      desc 'create job' do
        success REPRESENTER
      end
      params do
        requires :data, type: REPRESENTER, desc: 'job info'
      end
      post do
        guard do
          _job = DB_CLASS.new
          _job = parse_item(item: _job, representer: REPRESENTER)
          _job.save!
          present_item(item: _job, representer: REPRESENTER)
        end
      end

      params do
        requires :job_id, type: String, desc: 'job ID', allow_blank: false, job_id: true
      end
      route_param :job_id do

        desc 'get job information' do
          success REPRESENTER
        end
        params do
          use :field_selector
        end
        get do
          present_item(representer: REPRESENTER, item: job)
        end

        desc 'update job information' do
          success REPRESENTER
        end
        params do
          requires :data, type: REPRESENTER, desc: 'job info'
        end
        put do
          guard do
            _job = job
            parse_item(representer: REPRESENTER, item: _job)
            _job.save!
            present_item(representer: REPRESENTER, item: job)
          end
        end

        desc 'delete job'
        delete do
          guard do
            job.destroy
            api_success("job (#{declared(params).id}) deleted")
          end
        end

        desc 'set ingest model'
        params do
          requires :ingest_model_id, type: String, desc: 'ingest model ID', ingest_model_id: true
        end
        put 'ingest_model' do
          guard do
            _job = job
            _ingest_model = ingest_model
            # noinspection RubyResolve
            _job.ingest_model = _ingest_model
            _job.save!
            api_success("job '#{_job.name}' (#{_job.id}) ingest model set to '#{_ingest_model.name}' (#{_ingest_model.id})")
          end
        end

        desc 'set organization'
        params do
          requires :organization_id, type: String, desc: 'organization ID', organization_id: true
        end
        put 'organization' do
          guard do
            _job = job
            _organization = organization
            # noinspection RubyResolve
            _job.organization = _organization
            _job.save!
            api_success("job '#{_job.name}' (#{_job.id}) organization set to '#{_organization.name}' (#{_organization.id})")
          end
        end

        desc 'set workflow'
        params do
          requires :workflow_id, type: String, desc: 'workflow ID', workflow_id: true
        end
        put 'workflow' do
          guard do
            _job = job
            _workflow = workflow
            # noinspection RubyResolve
            _job.workflow = _workflow
            _job.save!
            api_success("job '#{_job.name}' (#{_job.id}) workflow set to '#{_workflow.name}' (#{_workflow.id})")
          end
        end

        namespace :runs do

          REPRESENTER_1 = Representer::Item

          desc 'get job runs' do
            success REPRESENTER_1
          end
          params do
            use :field_selector
          end
          get '' do
            guard do
              present_collection(representer: REPRESENTER_1, collection: job.runs)
            end
          end

        end # namespace :runs

        namespace :ingest_models do

          REPRESENTER_2 = Representer::IngestModel

          desc 'get job ingest_models' do
            success REPRESENTER_2
          end
          params do
            use :field_selector
          end
          get '' do
            guard do
              present_collection(representer: REPRESENTER_2, collection: job.ingest_models)
            end
          end

        end # namespace :ingest_models

      end # route_param :job_id

    end # namespace :jobs

  end # Class

end # Module