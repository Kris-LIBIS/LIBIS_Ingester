module Libis::Ingester::API::ParamHelper
  extend Grape::API::Helpers

  params :field_selector do
    optional :fields, type: Hash, desc: 'JSON-API field selector' do
      optional :users, type: String, desc: 'comma-separated list of user fields to display'
      optional :organizations, type: String, desc: 'comma-separated list of organization fields to display'
      optional :jobs, type: String, desc: 'comma-separated list of job fields to display'
      optional :items, type: String, desc: 'comma-separated list of item fields to display'
    end
  end

  params :user_fields do
    optional :fields, type: Hash, desc: 'JSON-API field selector' do
      optional :users, type: String, desc: 'comma-separated list of user fields to display'
    end
  end

  params :organization_fields do
    optional :fields, type: Hash, desc: 'JSON-API field selector' do
      optional :organizations, type: String, desc: 'comma-separated list of organization fields to display'
    end
  end

  params :job_fields do
    optional :fields, type: Hash, desc: 'JSON-API field selector' do
      optional :jobs, type: String, desc: 'comma-separated list of job fields to display'
    end
  end

  params :run_fields do
    optional :fields, type: Hash, desc: 'JSON-API field selector' do
      optional :runs, type: String, desc: 'comma-separated list of item fields to display'
    end
  end

  params :item_fields do
    optional :fields, type: Hash, desc: 'JSON-API field selector' do
      optional :items, type: String, desc: 'comma-separated list of item fields to display'
    end
  end

  params :ingest_model_fields do
    optional :fields, type: Hash, desc: 'JSON-API field selector' do
      optional :ingest_models, type: String, desc: 'comma-separated list of item fields to display'
    end
  end

  def fields_opts(fields, default = {})
    opts = Hash[fields.map {|t, f| [t.to_sym, f.split(/\s*,\s*/).map(&:to_sym)]}] rescue {}
    opts = default.merge opts
    opts.empty? ? {} : {fields: opts.select {|_, v| !v.nil?}}
  end

end