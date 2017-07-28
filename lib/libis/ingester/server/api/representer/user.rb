require_relative 'base'
require_relative 'organization'

module Libis::Ingester::API::Representer
  class User < Grape::Roar::Decorator
    include Base

    type :users

    attributes do
      property :name, type: String, desc: 'user name'
      property :role, type: String, desc: 'user role'

      property :password, exec_context: :decorator, type: String, desc: 'user password'
      def password
        '******'
      end
      def password=(pwd)
        represented.password = pwd unless /^\**$/ =~ pwd
      end

      property :organizations, exec_context: :decorator, type: Array,
               desc: 'list of IDs of organizations the user belongs to'
      def organizations
        represented.organizations.map { |org| org.id.to_s  rescue ''}
      end

      def organizations=(orgs)
        represented.organizations.clear
        orgs.each do |org_id|
          org = Libis::Ingester::Organization.find_by(id: org_id)
          represented.organizations << org
        end if orgs
      end
    end

    link(:organizations) do |opts|
      "#{self_url(opts)}/#{represented.id}/organizations"
    end

  end
end
