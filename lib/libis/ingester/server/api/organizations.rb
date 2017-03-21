require 'libis/ingester/organization'
require 'libis/ingester/server/api/representer/organizations'
require 'libis/ingester/server/api/representer/organization_detail'

module Libis::Ingester::API
  class Organizations < Grape::API
    include Grape::Kaminari

    namespace :organizations do

      desc 'get list of organizations' do
        success Representer::OrganizationsRepresenter
      end
      paginate per_page: 2, max_per_page: 10
      get '' do
        orgs = paginate(Libis::Ingester::Organization.all)
        Representer::OrganizationsRepresenter.new(orgs).to_hash(pagination_hash(orgs))
      end

      route_param :id do
        params do
          requires :id, type: String, desc: 'Organization ID', allow_blank: false
        end

        desc 'get organization information' do
          success Representer::OrganizationDetailRepresenter
        end
        get do
          org = Libis::Ingester::Organization.find(declared(params).id)
          Representer::OrganizationDetailRepresenter.new(org).to_hash(item_hash(org))
        end

        desc 'update organization information' do
          success Representer::OrganizationDetailRepresenter
        end
        params do
          requires :data, type: Representer::OrganizationDetailRepresenter, desc: 'Organization info'
        end
        put do
          org = Libis::Ingester::Organization.find(declared(params).id)
          Representer::OrganizationDetailRepresenter.new(org).from_hash(declared(params).data)
          org.save!
          Representer::OrganizationDetailRepresenter.new(org).to_hash(item_hash(org))
        end

      end

      desc 'create organization' do
        success Representer::OrganizationDetailRepresenter
      end
      params do
        requires :data, type: Representer::OrganizationDetailRepresenter, desc: 'Organization info'
      end
      post do
        org = Libis::Ingester::Organization.new
        Representer::OrganizationDetailRepresenter.new(org).from_hash(declared(params).data)
        org.save!
        Representer::OrganizationDetailRepresenter.new(org).to_hash(item_hash(org))
      end

    end

  end
end