#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'libis-ingester'

::Libis::Ingester.configure do |cfg|
  cfg.logger = ::Logger.new(STDOUT)
  cfg.set_log_formatter
  cfg.logger.level = Logger::DEBUG
end

require 'libis/ingester/installer'

installer = ::Libis::Ingester::Installer.new('site.config.yml')

require 'sidekiq'

Sidekiq.configure_server do |config|
  # noinspection RubyResolve
  config.redis = {url: installer.config.config.redis_url}
end
