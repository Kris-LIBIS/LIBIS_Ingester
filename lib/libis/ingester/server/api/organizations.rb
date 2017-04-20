require 'libis/ingester/organization'

module Libis::Ingester::API
  class Organizations < Grape::API
    include Grape::Kaminari

    REPRESENTER = Representer::Organization
    DB_CLASS = Libis::Ingester::Organization

    namespace :organizations do

      helpers ParamHelper
      helpers StatusHelper
      helpers RepresentHelper
      helpers ObjectHelper

      desc 'get list of organizations' do
        success REPRESENTER
      end
      paginate per_page: 10, max_per_page: 50
      params do
        use :field_selector
      end
      get '' do
        guard do
          present_collection(collection: paginate(DB_CLASS), representer: REPRESENTER, with_pagination: true)
        end
      end

      desc 'create organization' do
        success REPRESENTER
      end
      params do
        requires :data, type: REPRESENTER, desc: 'organization info'
      end
      post do
        guard do
          _organization = DB_CLASS.new
          _organization = parse_item(item: _organization, representer: REPRESENTER)
          _organization.save!
          present_item(item: _organization, representer: REPRESENTER)
        end
      end

      params do
        requires :organization_id, type: String, desc: 'organization ID', allow_blank: false, organization_id: true
      end
      route_param :organization_id do

        desc 'get organization information' do
          success REPRESENTER
        end
        params do
          use :field_selector
        end
        get do
          present_item(representer: REPRESENTER, item: organization)
        end

        desc 'update organization information' do
          success REPRESENTER
        end
        params do
          requires :data, type: REPRESENTER, desc: 'organization info'
        end
        put do
          guard do
            _organization = organization
            parse_item(representer: REPRESENTER, item: _organization)
            _organization.save!
            present_item(representer: REPRESENTER, item: organization)
          end
        end

        desc 'delete organization' do
        end
        delete do
          guard do
            organization.destroy
            api_success("organization (#{declared(params).id}) deleted")
          end
        end

        namespace :users do

          REPRESENTER_1 = Representer::User

          desc 'get organization users' do
            success REPRESENTER_1
          end
          params do
            use :field_selector
          end
          get '' do
            guard do
              present_collection(representer: REPRESENTER_1, collection: organization.users)
            end
          end

          params do
            requires :user_id, type: String, desc: 'user ID', allow_blank: false, user_id: true
          end
          route_param :user_id do

            desc 'add user to organization'
            put do
              guard do
                _organization = organization
                _user = user
                _organization.users.push(_user)
                _user.save!
                _organization.save!
                api_success("user '#{_user.name}' (#{_user.id}) added to organization '#{_organization.name}' (#{_organization.id})")
              end
            end

            desc 'remove user from organization'
            delete do
              _organization = organization
              _user = user
              _organization.users.delete(_user)
              _user.save!
              _organization.save!
              api_success("user '#{_user.name}' (#{_user.id}) removed from organization '#{_organization.name}' (#{_organization.id})")
            end

          end # route_param :user_id

        end # namespace :users

        namespace :jobs do

          REPRESENTER_2 = Representer::Job

          desc 'get organization jobs' do
            success REPRESENTER_2
          end
          params do
            use :field_selector
          end
          get '' do
            guard do
              present_collection(representer: REPRESENTER_2, collection: organization.jobs)
            end
          end

        end # namespace :jobs

      end # route_param :organization_id

    end # namespace :organizations

  end # Class

end # Module