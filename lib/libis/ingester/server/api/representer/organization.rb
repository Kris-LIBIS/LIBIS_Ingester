require_relative 'base'

module Libis::Ingester::API::Representer
  class Organization < Grape::Roar::Decorator
    include Base

    type :organizations

    attributes do
      property :name, type: String, desc: 'organization name'
      property :code, type: String, desc: 'institution code'
      property :material_flow, as: :material_flow, type: JSON, desc: 'supported material flows'
      property :ingest_dir, as: :ingest_dir, type: String, desc: 'directory where the SIPs will be uploaded'
      property :c_at, as: :created_at, writeable: false, type: DateTime, desc: 'Date when the organization was created'

      nested :producer do
         property :producer_id, as: :id, type: String, desc: 'producer identifier'
         property :producer_agent, as: :agent, type: String, desc: 'producer agent identifier'
         property :producer_pwd, as: :password, exec_context: :decorator, type: String, desc: 'producer agent password'
        def producer_pwd
          '******'
        end
        def producer_pwd=(pwd)
          represented.producer_pwd = pwd unless /^\**$/ =~ pwd
        end
      end

      property :users, as: :user_ids, exec_context: :decorator, type: Array, desc: 'list of IDs of users that belong to this organization'
      def users
        represented.users.map { |user| user.id.to_s }
      end

      def users=(users)
        # noinspection RubyResolve
        represented.user_ids = users.map { |user| user.id }
      end

    end

    link :users do |opts|
      "#{self.class.self_url(opts)}/#{represented.id}/users"
    end

    link :jobs do |opts|
      "#{self.class.self_url(opts)}/#{represented.id}/jobs"
    end

  end
end