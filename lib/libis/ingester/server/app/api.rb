module Libis::Ingester
  class Api < Grape::API
    version 'v1', using: :header, vendor: 'libis'
    format :json
    formatter :json, Grape::Formatter::Roar
    prefix :api

    helpers do
      def base_url
        "#{env['rack.url_scheme']}://#{env['SERVER_NAME']}:#{env['SERVER_PORT']}/"
      end

      def this_url
        "#{env['rack.url_scheme']}://#{env['SERVER_NAME']}:#{env['SERVER_PORT']}/#{'REQUEST_PATH'}"
      end

      def pagination_links(collection, base_url)
        base_url += "?per_page=#{declared(params).per_page}&page="
        links = {
            first: "#{base_url}1",
            last: "#{base_url}#{collection.total_pages}"
        }
        links[:prev] = "#{base_url}#{collection.current_page - 1}" if collection.current_page > 1
        links[:next] = "#{base_url}#{collection.current_page + 1}" if collection.current_page < collection.total_pages
        links
      end
    end

    mount Libis::Ingester::API::Organizations
    mount Libis::Ingester::API::Jobs
  end
end
