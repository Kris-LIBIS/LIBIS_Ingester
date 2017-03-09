require File.expand_path('../config/environment', __FILE__)

use Rack::Config do |env|
  env['api.tilt.root'] = File.expand_path('../api/representer', __FILE__)
end

run Libis::Ingester::App.instance
