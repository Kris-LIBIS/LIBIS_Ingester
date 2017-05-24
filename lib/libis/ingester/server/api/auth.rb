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
            api_error(401, 'Authentication failed');
          end
          api_success(jwt_encode({user: {id: user.id, name: user.name, role: user.role}}))
        end
      end

    end # namespace :auth

  end # Class

end # Module