require 'grape-swagger'
require 'grape-swagger/representable'
require 'libis/ingester/server/api/representer/status'

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

      def pagination_hash(collection, default = {})
        option_hash(default).tap do |h|
          h[:user_options].merge!(
              pagination: {
                  page: collection.current_page,
                  total: collection.total_pages,
                  per: declared(params).per_page
              }
          )
        end
      end

      def meta_hash(collection)
        {
            per_page: collection.limit_value,
            total: collection.total_count,
            current_page: collection.current_page,
            total_pages: collection.total_pages,
            next_page: collection.next_page,
            prev_page: collection.prev_page
        }
      end

      def item_links(item, base_url)
        {
            self: "#{base_url}/#{item.id}",
            all: "#{base_url}",
        }
      end

      def item_hash(item, default = {})
        option_hash(default).tap do |h|
          h[:user_options].merge!(links: item_links(item, "#{base_url}#{namespace}"))
        end
      end

      def option_hash(default = {})
        default.dup.tap do |h|
          (h[:user_options] ||= {})[:base_url] = base_url
          # noinspection RubyResolve
          (h[:user_options] ||= {})[:this_url] = @request.url
        end
      end

      def fields_opts(fields, default = {})
        opts = Hash[fields.map {|t, f| [t.to_sym, f.split(/\s*,\s*/).map(&:to_sym)]}] rescue {}
        opts = default.merge opts
        opts.empty? ? {} : {fields: opts.select {|_, v| !v.nil?}}
      end

      def api_error(code, message)
        error!(message, code)
      end

      def api_success(message = nil)
        status 200
        { message: message }
        # obj = Hashie::Mash.new
        # obj.message = message
        # API::Representer::Status.prepare(obj)
      end

      def mongoid_guard
        yield
      rescue Mongoid::Errors::MongoidError => e
        api_error(400, "#{e.problem} #{e.summary}")
      end

      def user(id = nil)
        Libis::Ingester::User.find(id || declared(params).id)
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
