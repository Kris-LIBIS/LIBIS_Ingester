require_relative 'organization'

module Libis::Ingester::API::Representer
  class OrganizationsRepresenter < Grape::Roar::Decorator
    include Roar::JSON
    include Representable::Hash
    include Representable::Hash::AllowSymbols

    include Roar::JSON::JSONAPI::Mixin
    include Roar::Contrib::Decorator::CollectionRepresenter

    type :organizations

  end
end