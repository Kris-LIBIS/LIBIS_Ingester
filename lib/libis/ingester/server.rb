require 'libis/ingester'
require 'libis/ingester/initializer'

module Libis
  module Ingester

    class Server
      def initialize(config_file = 'site.config.yml')
        Initializer.init(config_file)
      end

    end

  end
end
