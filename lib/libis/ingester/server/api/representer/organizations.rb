require_relative 'organization'
require_relative 'item_collection'

module Libis::Ingester::API::Representer
  class OrganizationsRepresenter < Grape::Roar::Decorator
    include ItemCollection

    type :organizations

  end
end