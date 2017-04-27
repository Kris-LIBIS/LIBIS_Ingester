module Libis::Ingester::API::ObjectHelper
  extend Grape::API::Helpers

  def current_user(id = nil)
    Libis::Ingester::User.find(id || params[:user_id])
  end

  def current_organization(id = nil)
    Libis::Ingester::Organization.find(id || params[:organization_id])
  end

  def current_job(id = nil)
    Libis::Ingester::Job.find(id || params[:job_id])
  end

  def current_run(id = nil)
    Libis::Ingester::Run.find(id || params[:run_id])
  end

  def current_item(id = nil)
    Libis::Ingester::Item.find(id || params[:item_id])
  end

  def current_ingest_model(id = nil)
    Libis::Ingester::IngestModel.find(id || params[:ingest_model_id])
  end

  def current_workflow(id = nil)
    Libis::Ingester::Workflow.find(id || params[:workflow_id])
  end

end
