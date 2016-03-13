$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'libis-ingester'

require 'libis/ingester/installer'

installer = ::Libis::Ingester::Installer.new('site.config.yml')

require 'sidekiq'

Sidekiq.configure_server do |config|
  # noinspection RubyResolve
  config.redis = {url: installer.config.sidekiq.redis_url}
end
