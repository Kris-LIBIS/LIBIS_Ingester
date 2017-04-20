require_relative 'api_helpers'
require_relative 'api_representers'
require_relative 'api_validators'

module Libis::Ingester
  module API
    autoload :Users, 'libis/ingester/server/api/users'
    autoload :Organizations, 'libis/ingester/server/api/organizations'
    autoload :Jobs, 'libis/ingester/server/api/jobs'
    autoload :Runs, 'libis/ingester/server/api/runs'
  end
end
