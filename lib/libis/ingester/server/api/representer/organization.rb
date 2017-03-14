require_relative 'item_list'

module Libis::Ingester::API::Representer
  class OrganizationRepresenter < Grape::Roar::Decorator
    include ItemList

    type :organization

    attributes do
      property :name, type: String, desc: 'organization name'
    end

  end
end