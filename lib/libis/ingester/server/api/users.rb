require 'libis/ingester/user'

module Libis::Ingester::API
  class Users < Grape::API
    include Grape::Kaminari

    REPRESENTER = Representer::User
    DB_CLASS = Libis::Ingester::User

    namespace :users do

      helpers ParamHelper
      helpers StatusHelper
      helpers RepresentHelper
      helpers ObjectHelper

      desc 'get list of users' do
        success REPRESENTER
      end
      paginate per_page: 10, max_per_page: 50
      params do
        use :user_fields
      end
      get '' do
        guard do
          present_collection(collection: paginate(DB_CLASS), representer: REPRESENTER, with_pagination: true)
        end
      end

      desc 'create user' do
        success REPRESENTER
      end
      params do
        requires :data, type: REPRESENTER, desc: 'user info'
      end
      post do
        guard do
          _user = DB_CLASS.new
          _user = parse_item(item: _user, representer: REPRESENTER)
          _user.save!
          present_item(item: _user, representer: REPRESENTER)
        end
      end

      params do
        requires :user_id, type: String, desc: 'user ID', allow_blank: false, user_id: true
      end
      route_param :user_id do

        desc 'get user information' do
          success REPRESENTER
        end
        params do
          use :user_fields
        end
        get do
          present_item(representer: REPRESENTER, item: current_user)
        end

        desc 'update user information' do
          success REPRESENTER
        end
        params do
          requires :data, type: REPRESENTER, desc: 'user info'
        end
        put do
          guard do
            _user = current_user
            parse_item(representer: REPRESENTER, item: _user)
            _user.save!
            present_item(representer: REPRESENTER, item: current_user)
          end
        end

        desc 'update user information' do
          success REPRESENTER
        end
        params do
          requires :data, type: REPRESENTER, desc: 'user info'
        end
        patch do
          guard do
            _user = current_user
            parse_item(representer: REPRESENTER, item: _user)
            _user.save!
            present_item(representer: REPRESENTER, item: current_user)
          end
        end

        desc 'delete user' do
        end
        delete do
          guard do
            current_user.destroy
            api_success("user (#{declared(params)[:user_id]}) deleted")
          end
        end

        namespace :organizations do

          REPRESENTER_1 = Representer::Organization

          desc 'get user organizations' do
            success REPRESENTER_1
          end
          params do
            use :organization_fields
          end
          get '' do
            guard do
              present_collection(representer: REPRESENTER_1, collection: current_user.organizations)
            end
          end

          desc 'set user organization list' do
            success REPRESENTER
          end
          params do
            requires :organization_ids, type: Array, desc: 'list of organization IDs', allow_blank: false, organization_ids: true
          end
          post '' do
            guard do
              _user = current_user
              _user.organizations.clear
              _orgs = []
              params['organization_ids'].each do |org_id|
                _organization = organization(org_id)
                _user.organizations.push(_organization)
                _orgs.push _organization
              end
              _user.save!
              present_item(representer: REPRESENTER, item: current_user)
            end
          end

          params do
            requires :organization_id, type: String, desc: 'organization ID', allow_blank: false, organization_id: true
          end
          route_param :organization_id do

            desc 'add organization to user'
            put do
              guard do
                _user = current_user
                _organization = organization
                _user.organizations.push(_organization)
                _organization.save!
                _user.save!
                api_success("organization '#{_organization.name}' (#{_organization.id}) added to user '#{_user.name}' (#{_user.id})")
              end
            end

            desc 'remove organization from user'
            delete do
              _user = current_user
              _organization = organization
              _user.organizations.delete(_organization)
              _organization.save!
              _user.save!
              api_success("organization '#{_organization.name}' (#{_organization.id}) removed from user '#{_user.name}' (#{_user.id})")
            end

          end # route_param :organization_id

        end # namespace :organizations

      end # route_param :user_id

    end # namespace :users

  end # Class

end # Module