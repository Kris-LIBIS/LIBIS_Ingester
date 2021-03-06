module Libis::Ingester
  class App
    def initialize
      @filenames = ['', '.html', 'index.html', '/index.html']
      @static_doc = ::Rack::Static.new(
          lambda { |e| [404, {}, []] },
          root: File.expand_path('../../web', __FILE__),
          urls: ['/']
      )
    end

    def self.instance
      @instance ||= Rack::Builder.new do
        use Rack::Cors do
          allow do
            origins '*'
            resource '*', headers: :any, methods: [:get, :post, :put, :delete, :options, :patch]
          end
        end

        run Libis::Ingester::App.new
      end.to_app
    end

    def call(env)
      # api
      response = Libis::Ingester::Api.call(env)

      # Check if the App wants us to pass the response along to others
      if response[1]['X-Cascade'] == 'pass'
        # static files
        request_path = env['PATH_INFO']
        @filenames.each do |path|
          response = @static_doc.call(env.merge('PATH_INFO' => request_path + path))
          return response if response[0] != 404
        end
      end

      # Serve error pages or respond with API response
      case response[0]
        when 404, 500
          content = @static_doc.call(env.merge('PATH_INFO' => "/errors/#{response[0]}.html"))
          [response[0], content[1], content[2]]
        else
          response
      end
    end
  end
end
