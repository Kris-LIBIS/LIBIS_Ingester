module Libis::Ingester::API::ParamHelper
  extend Grape::API::Helpers

  params :field_selector do
    optional :fields, type: Hash, desc: 'JSON-API field selector' do
      optional :user, type: String, desc: 'comma-separated list of user fields to display'
      optional :organization, type: String, desc: 'comma-separated list of organization fields to display'
      optional :job, type: String, desc: 'comma-separated list of job fields to display'
      optional :item, type: String, desc: 'comma-separated list of item fields to display'
    end
  end

  def fields_opts(fields, default = {})
    opts = Hash[fields.map {|t, f| [t.to_sym, f.split(/\s*,\s*/).map(&:to_sym)]}] rescue {}
    opts = default.merge opts
    opts.empty? ? {} : {fields: opts.select {|_, v| !v.nil?}}
  end

end