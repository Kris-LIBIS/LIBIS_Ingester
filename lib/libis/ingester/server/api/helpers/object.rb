module Libis::Ingester::API::ObjectHelper
  extend Grape::API::Helpers

  def current_user(id = nil)
    Libis::Ingester::User.find_by(id: id || params[:user_id])
  end

  def current_organization(id = nil)
    Libis::Ingester::Organization.find_by(id: id || params[:organization_id])
  end

  def current_job(id = nil)
    Libis::Ingester::Job.find_by(id: id || params[:job_id])
  end

  def current_run(id = nil)
    Libis::Ingester::Run.find_by(id: id || params[:run_id])
  end

  def current_item(id = nil)
    Libis::Ingester::Item.find_by(id: id || params[:item_id])
  end

  def current_ingest_model(id = nil)
    Libis::Ingester::IngestModel.find_by(id: id || params[:ingest_model_id])
  end

  def current_workflow(id = nil)
    Libis::Ingester::Workflow.find_by(id: id || params[:workflow_id])
  end

end
