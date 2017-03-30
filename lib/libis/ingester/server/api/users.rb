require 'libis/ingester/server/api/representer/error'
require 'libis/ingester/user'
require 'libis/ingester/server/api/representer/user'
require 'libis/ingester/server/api/validator/user_id'

module Libis::Ingester::API
  class Users < Grape::API
    include Grape::Kaminari

    namespace :users do

      desc 'get list of users' do
        success Representer::User
        # failure Representer::Error
      end
      paginate per_page: 2, max_per_page: 10
      params do
        optional :relations, type: Boolean, desc: 'Include related organizations', default: true
      end
      get '' do
        users = paginate(Libis::Ingester::User.all)
        Representer::User.for_pagination.prepare(users)
            .to_hash(pagination_hash(users, declared(params).relations ? {} : {fields: {users: [:name, :role]}})
            )
      end

      desc 'create user' do
        success Representer::User
        # failure Representer::Error
      end
      params do
        requires :data, type: Representer::User, desc: 'User info'
      end
      post do
        begin
          user = Libis::Ingester::User.new
          Representer::User.prepare(user).from_hash(declared(params))
          user.save!
          Representer::User.prepare(user).to_hash(item_hash(user))
        rescue Mongo::Error => e
          api_error(500, e.message).to_hash
        end
      end

      route_param :id do
        params do
          requires :id, type: String, desc: 'User ID', allow_blank: false, user_id: true
        end

        namespace do

          desc 'get user information' do
            success Representer::User
          end
          params do
            optional :fields, type: Hash, desc: 'Field selection as comma-separated list in a Hash with item type as key.'
          end
          get do
            user = Libis::Ingester::User.find(declared(params).id)
            Representer::User.prepare(user)
                .to_hash(item_hash(user)
                # .merge(fields_opts(declared(params).fields, {jobs: nil}))
                )
          end

          desc 'get user organizations' do
            success Representer::OrganizationRepresenter
          end
          params do
            optional :fields, type: Hash, desc: 'Field selection as comma-separated list in a Hash with item type as key.'
          end
          get 'organizations' do
            orgs = Libis::Ingester::User.find(declared(params).id).organizations
            Representer::OrganizationRepresenter.for_collection.prepare(orgs)
                .to_hash(option_hash
                # .merge(fields_opts(declared(params).fields, {jobs: nil}))
                ) if orgs
          end

          desc 'update user information' do
            success Representer::User
          end
          params do
            requires :data, type: Representer::User, desc: 'User info'
          end
          put do
            user = Libis::Ingester::User.find(declared(params).id)
            Representer::User.new(user).from_hash(declared(params))
            user.save!
            Representer::User.new(user).to_hash(item_hash(user))
          end

        end

      end

    end

  end
end