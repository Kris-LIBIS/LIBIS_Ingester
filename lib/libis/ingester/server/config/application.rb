$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'api'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'boot'

Bundler.require :default, ENV['RACK_ENV']

require 'rack/cors'

require 'grape'
require 'roar'
require 'grape-roar'
require 'roar/json'
require 'grape-kaminari'
require 'kaminari/mongoid'
require 'roar/json/json_api'
require 'roar-contrib'

Dir[File.expand_path('../../api/*.rb', __FILE__)].each do |f|
  # noinspection RubyResolve
  require f
end

# noinspection RubyResolve
require 'api'
# noinspection RubyResolve
require 'ingester_api_app'
