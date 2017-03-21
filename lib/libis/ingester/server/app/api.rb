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

      def this_url
        "#{host_url}/#{env['REQUEST_PATH']}"
      end

      def pagination_links(collection, base_url)
        base_url += "?per_page=#{declared(params).per_page}&page="
        links = {
            self: "#{base_url}#{collection.current_page}",
            first: "#{base_url}1",
            last: "#{base_url}#{collection.total_pages}"
        }
        links[:prev] = "#{base_url}#{collection.current_page - 1}" if collection.current_page > 1
        links[:next] = "#{base_url}#{collection.current_page + 1}" if collection.current_page < collection.total_pages
        links
      end

      def pagination_hash(collection)
        {
            user_options: {
                base_url: "#{base_url}#{namespace}",
                links: pagination_links(collection, "#{base_url}#{namespace}")
            },
            meta: {
                per_page: collection.limit_value,
                total: collection.total_count,
                page: collection.current_page,
                max_page: collection.total_pages,
                next_page: collection.next_page,
                prev_page: collection.prev_page,
            }
        }
      end

      def item_links(item, base_url)
        {
            self: "#{base_url}/#{item.id}",
            all: "#{base_url}",
        }
      end

      def item_hash(item)
        {
            user_options: {
                links: item_links(item, "#{base_url}#{namespace}")
            }
        }
      end

    end

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
      redirect "#{host_url}/index.html?url=http://localhost:9393/api/swagger_doc"
    end
  end
end
