$:.unshift File.join(__dir__, '..', '..', '..')
require 'libis-ingester'

require 'libis/ingester/initializer'

::Libis::Ingester::Initializer.init('site.config.yml')
