require_relative 'base'
require_relative 'organization'

module Libis::Ingester::API::Representer
  class User < Grape::Roar::Decorator
    include Base

    type :users

    attributes do
      property :name, type: String, desc: 'user name'
      property :_role, as: :role, type: String, desc: 'user role'
    end

    link(:organizations) { |opts| "#{self_url(opts.reject {|k,_| k == :pagination})}/#{represented.id}/organizations" }

    has_many :organizations, extend: OrganizationRepresenter,
             class: Libis::Ingester::Organization,
             populator: ::Representable::FindOrInstantiate do
      relationship do
        link :self do |opts|
          "#{opts[:base_url]}/users/#{represented.id}/organizations"
        end
      end
    end

  end
end