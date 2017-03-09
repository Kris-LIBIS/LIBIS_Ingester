require 'rubygems'
require 'bundler/setup'

require 'libis-ingester'

require 'libis/ingester/initializer'

::Libis::Ingester::Initializer.init(ENV['SITE_CONFIG'])
