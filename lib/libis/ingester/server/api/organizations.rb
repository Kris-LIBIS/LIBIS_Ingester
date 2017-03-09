require 'libis/ingester/organization'
require 'libis/ingester/server/api/representer/organizations'
require 'libis/ingester/server/api/representer/organization_detail'

module Libis::Ingester::API
  class Organizations < Grape::API
    include Grape::Kaminari

    namespace :organizations do

      desc 'get list of organizations'
      paginate per_page: 2, max_per_page: 10
      get '' do
        orgs = paginate(Libis::Ingester::Organization.all)
        Representer::OrganizationsRepresenter.for_collection.new(orgs).to_hash(
            user_options: {
                base_url: "#{base_url}api/organizations/",
                links: pagination_links(orgs, "#{base_url}/api/organizations")
            },
        )
      end

      namespace do
        params do
          requires :id, type: String, desc: 'Organization ID', allow_blank: false
        end

        desc 'get organization information'
        get ':id' do
          org = Libis::Ingester::Organization.find(declared(params).id)
          Representer::OrganizationDetailRepresenter.new(org).to_hash(
              user_options: {
                  base_url: "#{env['rack.url_scheme']}://#{env['SERVER_NAME']}:#{env['SERVER_PORT']}/"
              }
          )
        end

        desc 'update organization information'
        params do
        end
        put do

        end

      end

    end

  end
end