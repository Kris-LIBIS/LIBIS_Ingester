require_relative 'organization'

require 'roar/json/json_api'

module Libis::Ingester::API::Representer
  class OrganizationCollection < Grape::Roar::Decorator
    include Roar::JSON
    include Representable::Hash
    include Representable::Hash::AllowSymbols

    include Roar::JSON::JSONAPI::Mixin

    link(:first) { |opts| opts[:links][:first] }
    link(:last) { |opts| opts[:links][:last] }
    link(:prev) { |opts| opts[:links][:prev] }
    link(:next) { |opts| opts[:links][:next] }

    collection :orgs, as: :data, extend: OrganizationRepresenter

    def orgs
      self
    end

  end
end