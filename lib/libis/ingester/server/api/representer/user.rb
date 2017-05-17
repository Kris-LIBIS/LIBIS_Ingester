require_relative 'base'
require_relative 'organization'

module Libis::Ingester::API::Representer
  class User < Grape::Roar::Decorator
    include Base

    type :users

    attributes do
      property :name, type: String, desc: 'user name'
      property :role, type: String, desc: 'user role'
      property :orgs, as: :organizations, exec_context: :decorator,
               type: Array, desc: 'user organizations'
      def orgs
        represented.organizations.map { |org| {id: org.id.to_s, name: org.name } }
      end

      def orgs=(orgs)
        represented.organizations.clear
        orgs.each do |org_id|
          org = Libis::Ingester::Organization.find(org_id)
          represented.organizations.add(org)
        end
      end
    end

    link(:organizations) do |opts|
      "#{self_url(opts)}/#{represented.id}/organizations"
    end

  end
end