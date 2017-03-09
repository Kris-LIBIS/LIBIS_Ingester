require_relative 'base'

module Libis::Ingester::API::Representer
  class OrganizationRepresenter < Base
    include Roar::JSON
    include Representable::Hash
    include Representable::Hash::AllowSymbols

    type :organization

    attributes do
      property :name, type: 'String', desc: 'organization name'
    end

    link :self do |opts|
      "#{opts[:base_url]}#{represented.id}"
    end

  end
end