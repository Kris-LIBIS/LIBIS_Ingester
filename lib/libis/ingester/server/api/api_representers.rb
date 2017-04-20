module Libis::Ingester::API
  module Representer
    autoload :User, 'libis/ingester/server/api/representer/user'
    autoload :Organization, 'libis/ingester/server/api/representer/organization'
    autoload :Job, 'libis/ingester/server/api/representer/job'
    autoload :Item, 'libis/ingester/server/api/representer/item'
    autoload :Item, 'libis/ingester/server/api/representer/ingest_model'
  end
end