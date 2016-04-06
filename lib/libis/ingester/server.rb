require 'libis/ingester'
require 'libis/ingester/initializer'

module Libis
  module Ingester

    class Server
      def initialize(config_file = 'site.config.yml')
        Initializer.new(config_file)
      end

    end

  end
end
