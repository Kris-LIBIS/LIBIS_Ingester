$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'libis-ingester'

require 'libis/ingester/initializer'

::Libis::Ingester::Initializer.new('site.config.yml')
