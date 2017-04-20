module Libis::Ingester::API::ObjectHelper
  extend Grape::API::Helpers

  def user(id = nil)
    Libis::Ingester::User.find(id || params[:user_id])
  end

  def organization(id = nil)
    Libis::Ingester::Organization.find(id || params[:organization_id])
  end

  def job(id = nil)
    Libis::Ingester::Job.find(id || params[:job_id])
  end

  def item(id = nil)
    Libis::Ingester::Item.find(id || params[:item_id])
  end

  def ingest_model(id = nil)
    Libis::Ingester::IngestModel.find(id || params[:ingest_model_id])
  end

  def workflow(id = nil)
    Libis::Ingester::Workflow.find(id || params[:workflow_id])
  end

end
