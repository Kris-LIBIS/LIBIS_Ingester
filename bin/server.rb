$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'libis-ingester'

require 'libis/ingester/installer'

installer = ::Libis::Ingester::Installer.new('site.config.yml')

require_relative 'sidekiq.server.config'
