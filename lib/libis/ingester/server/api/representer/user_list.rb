require_relative 'base'
require_relative 'organization'

module Libis::Ingester::API::Representer
  class UserRepresenter < Grape::Roar::Decorator
    include Base

    type :users

    attributes do
      property :name, type: String, desc: 'user name'
      property :_role, as: :role, type: String, desc: 'user role'
    end

    link(:organizations) { |opts| "#{self.class.self_url(opts.reject {|k,_| k == :pagination})}/#{represented.id}/organizations" }

    has_many :organizations,
             class: Libis::Ingester::Organization,
             decorator: OrganizationRepresenter,
             populator: ::Representable::FindOrInstantiate

  end
end