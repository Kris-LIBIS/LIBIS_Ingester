require 'libis/ingester/server/api/representer/status'
require 'libis/ingester/user'
require 'libis/ingester/server/api/representer/user'
require 'libis/ingester/server/api/validator/user_id'

module Libis::Ingester::API
  class Users < Grape::API
    include Grape::Kaminari

    namespace :users do

      desc 'get list of users' do
        success Representer::User
      end
      params do
        optional :fields, type: Hash, desc: 'Field selection as comma-separated list in a Hash with item type as key.'
      end
      paginate per_page: 10, max_per_page: 50
      get '' do
        mongoid_guard do
          users = paginate(Libis::Ingester::User.all)
          Representer::User.for_pagination.prepare(users)
              .to_hash(
                  pagination_hash(users, {})
                      .merge(fields_opts(declared(params).fields, {}))
              )
        end
      end

      desc 'create user' do
        success Representer::User
      end
      params do
        requires :data, type: Representer::User, desc: 'User info'
      end
      post do
        mongoid_guard do
          user = Libis::Ingester::User.new
          Representer::User.prepare(user).from_hash(declared(params))
          user.save!
          Representer::User.prepare(user).to_hash(item_hash(user))
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
            optional :fields, type: Hash,
                     desc: 'Field selection as comma-separated list in a Hash with item type as key.'
          end
          get do
            Representer::User.prepare(user).
                to_hash(item_hash(user).merge(fields_opts(declared(params).fields)))
          end

          desc 'get user organizations' do
            success Representer::OrganizationRepresenter
          end
          params do
            optional :fields, type: Hash, desc: 'Field selection as comma-separated list in a Hash with item type as key.'
          end
          get 'organizations' do
            mongoid_guard do
              orgs = user.organizations || []
              Representer::OrganizationRepresenter.for_collection.prepare(orgs).
                  to_hash(option_hash.merge(fields_opts(declared(params).fields)))
            end
          end

          desc 'update user information' do
            success Representer::User
          end
          params do
            requires :data, type: Representer::User, desc: 'User info'
          end
          put do
            mongoid_guard do
              Representer::User.new(user).from_hash(declared(params))
              user.save!
              Representer::User.new(user).to_hash(item_hash(user))
            end
          end

          desc 'delete user' do
          end
          delete do
            mongoid_guard do
              user.destroy
              api_success("User with id '#{declared(params).id}' deleted.")
            end
          end

        end

      end

    end

  end

end