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

      def pagination_links(_collection, _base_url)
        _base_url += "?per_page=#{declared(params).per_page}&page="
        links = {
            self: "#{_base_url}#{_collection.current_page}",
            first: "#{_base_url}1",
            last: "#{_base_url}#{_collection.total_pages}"
        }
        links[:prev] = "#{_base_url}#{_collection.current_page - 1}" if _collection.current_page > 1
        links[:next] = "#{_base_url}#{_collection.current_page + 1}" if _collection.current_page < _collection.total_pages
        links
      end

      def pagination_hash(_collection)
        option_hash.tap do |h|
          h[:user_options].merge!(
              pagination: {
                  page: _collection.current_page,
                  total: _collection.total_pages,
                  per: declared(params).per_page
              },
              links: pagination_links(_collection, "#{base_url}#{namespace}")
          )
        end
      end

      def meta_hash(_collection)
        {
            per_page: _collection.limit_value,
            total: _collection.total_count,
            current_page: _collection.current_page,
            total_pages: _collection.total_pages,
            next_page: _collection.next_page,
            prev_page: _collection.prev_page
        }
      end

      def item_links(_item, _base_url)
        {
            self: "#{_base_url}/#{_item.id}",
            all: "#{_base_url}",
        }
      end

      def item_hash(_item)
        option_hash.tap do |h|
          h[:user_options].merge!(links: item_links(_item, "#{base_url}#{namespace}"))
        end
      end

      def option_hash
        {
            user_options: {
                base_url: base_url
            }
        }
      end

      def fields_opts(_fields, _default = {})
        opts = Hash[_fields.map { |t, f| [t.to_sym, f.split(/\s*,\s*/).map(&:to_sym)] }] rescue {}
        opts = _default.merge opts
        opts.empty? ? {} : {fields: opts.select { |_, v| !v.nil? }}
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
      redirect "#{host_url}/index.html?url=http://localhost:9393/api/swagger_doc"
    end

    route :any do
      error! 'Lost your way?', 200
    end
  end
end
