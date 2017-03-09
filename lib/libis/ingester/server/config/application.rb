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

# class Roar::JSON::JSONAPI::Renderer::Links
#   def call(res, options)
#     ((res.delete('links') || []) + (options.delete(:links) || {}).map { |key, value|
#       {'rel' => key.to_s, 'href' => value}
#     }).collect { |link|
#       [Roar::JSON::JSONAPI::MemberName.(link['rel']), link['href']]
#     }.to_h
#   end
# end

Dir[File.expand_path('../../api/*.rb', __FILE__)].each do |f|
  # noinspection RubyResolve
  require f
end

# noinspection RubyResolve
require 'api'
# noinspection RubyResolve
require 'ingester_api_app'
