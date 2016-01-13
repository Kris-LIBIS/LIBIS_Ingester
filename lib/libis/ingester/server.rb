require 'libis/ingester'
require 'libis/ingester/installer'
require 'sidekiq'

module Libis
  module Ingester

    class Server
      def initialize(config_file = 'site.config.yml')
        installer = Installer.new(config_file)
        Sidekiq.configure_server do |config|
          # noinspection RubyResolve
          config.redis = { url: installer.config.config.redis_url }
        end
      end

    end

  end
end
