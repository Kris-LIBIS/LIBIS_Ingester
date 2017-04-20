require 'grape-swagger'
require 'grape-swagger/representable'

module Libis::Ingester
  class Api < Grape::API

    version 'v1', using: :header, vendor: 'libis'
    format :json
    formatter :json, Grape::Formatter::Roar
    prefix :api

    helpers do

      def host_url
        "#{env['rack.url_scheme']}://#{env['SERVER_NAME']}:#{env['SERVER_PORT']}"
      end

      def base_url
        "#{host_url}/api"
      end

    end

    helpers do

      def user(id = nil)
        Libis::Ingester::User.find(id || params[:usr_id])
      end

      def organization(id = nil)
        Libis::Ingester::Organization.find(id || params[:org_id])
      end

    end

    mount Libis::Ingester::API::Users
    mount Libis::Ingester::API::Organizations
    mount Libis::Ingester::API::Jobs

    add_swagger_documentation info: {
        title: 'Teneo Ingester API.',
        description: 'The Teneo Ingester API is a REST webservice using JSONAPI syntax.',
        contact_name: 'Kris Dekeyser',
        contact_email: 'kris.dekeyser@libis.be',
        license: 'MIT',
        license_url: 'https://opensource.org/licenses/MIT',
        terms_of_service_url: '',
    }

    get 'help' do
      redirect "#{host_url}/doc/index.html?url=http://localhost:9393/api/swagger_doc"
    end

    route :any do
      error! 'Lost your way?', 200
    end
  end
end
