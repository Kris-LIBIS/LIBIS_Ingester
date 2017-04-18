require_relative 'base'
require_relative 'organization'

module Libis::Ingester::API::Representer
  class User < Grape::Roar::Decorator
    include Base

    type :users

    attributes do
      property :name, type: String, desc: 'user name'
      property :role, type: String, desc: 'user role'
    end

    link(:organizations) do |opts|
      "#{self_url(opts)}/#{represented.id}/organizations"
    end

  end
end