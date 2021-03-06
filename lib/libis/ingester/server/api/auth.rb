require 'libis/ingester/user'

module Libis::Ingester::API
  class Auth < Grape::API
    include Grape::Kaminari

    DB_CLASS = Libis::Ingester::User
    SECRET = ENV['JWT_SECRET']

    namespace :auth do

      helpers StatusHelper
      helpers TokenHelper

      desc 'log in' do
      end
      params do
        requires :name, type: String, desc: 'user name'
        requires :password, type: String, desc: 'password'
      end
      post '' do
        guard do
          user = Libis::Ingester::User.authenticate(declared(params).name, declared(params).password)
          unless user
            api_error(401, 'Wrong user name or password');
          end
          api_success(jwt_encode({user: {id: user.id.to_s, name: user.name, role: user.role}}))
        end
      end

      desc 'renew token' do
      end
      params do
        requires :token, type: String, desc: 'active JWT'
      end
      patch '' do
        api_success(jwt_refresh(declared(params).token))
      end
    end # namespace :auth

  end # Class

end # Module