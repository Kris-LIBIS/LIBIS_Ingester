require 'libis/ingester/organization'
require 'libis/ingester/server/api/representer/organization'
require 'representable/debug'

module Libis::Ingester::API
  class Organizations < Grape::API
    include Grape::Kaminari

    namespace :organizations do

      desc 'get list of organizations' do
        success Representer::OrganizationRepresenter
      end
      paginate per_page: 2, max_per_page: 10
      params do
        optional :fields, type: Hash, desc: 'Field selection as comma-separated list in a Hash with item type as key.'
      end
      get '' do
        orgs = paginate(Libis::Ingester::Organization.all)
        Representer::OrganizationRepresenter.for_collection.prepare(orgs).
            # extend(Representable::Debug).
            to_hash(pagination_hash(orgs)
            # .merge(include: [:jobs])
            # .merge(fields_opts(declared(params).fields, {organizations: [:name]}))
            )
      end

      desc 'create organization' do
        success Representer::OrganizationRepresenter
      end
      params do
        requires :data, type: Representer::OrganizationRepresenter, desc: 'Organization info'
      end
      post do
        org = Libis::Ingester::Organization.new
        Representer::OrganizationRepresenter.prepare(org).from_hash(declared(params))
        org.save!
        Representer::OrganizationRepresenter.prepare(org).to_json(item_hash(org))
      end

      route_param :id do
        params do
          requires :id, type: String, desc: 'Organization ID', allow_blank: false
        end

        namespace do

          desc 'get organization information' do
            success Representer::OrganizationRepresenter
          end
          params do
            optional :fields, type: Hash, desc: 'Field selection as comma-separated list in a Hash with item type as key.'
          end
          get do
            org = Libis::Ingester::Organization.find(declared(params).id)
            Representer::OrganizationRepresenter.prepare(org).
                to_hash(
                    item_hash(org)
                        # .merge(fields_opts(declared(params).fields, {organizations: nil}))
                )
          end

          desc 'get jobs of an organization' do
            success Representer::JobRepresenter
          end
          paginate per_page: 4, max_per_page: 10
          params do
            optional :fields, type: Hash, desc: 'Field selection as comma-separated list in a Hash with item type as key.'
          end
          get 'jobs' do
            jobs = paginate(Libis::Ingester::Job.all)
            Representer::JobRepresenter.for_collection.prepare(jobs).
                to_hash(
                    pagination_hash(jobs)
                        # .merge(fields_opts(declared(params).fields, {jobs: [:name, :description]}))
                )
          end

          desc 'update organization information' do
            success Representer::OrganizationRepresenter
          end
          params do
            requires :data, type: Representer::OrganizationRepresenter, desc: 'Organization info'
          end
          put do
            org = Libis::Ingester::Organization.find(declared(params).id)
            Representer::OrganizationRepresenter.new(org).from_hash(declared(params))
            org.save!
            Representer::OrganizationRepresenter.new(org).to_hash(item_hash(org))
          end

        end

      end

    end

  end
end