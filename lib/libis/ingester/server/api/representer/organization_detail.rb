require_relative 'organization'
require_relative 'item_detail'

module Libis::Ingester::API::Representer
  class OrganizationDetailRepresenter < OrganizationRepresenter

    include ItemDetail

    attributes do
      property :code, type: String, desc: 'institution code'
      property :material_flow, type: JSON, desc: 'supported material flows'
      property :ingest_dir, type: String, desc: 'directory where the SIPs will be uploaded'
      property :c_at, as: :created_at, writable: false, type: DateTime, desc: 'Date when the organization was created'

      nested :producer do
        property :producer_id, as: :id, type: 'String', desc: 'producer identifier'
        property :producer_agent, as: :agent, type: 'String', desc: 'producer agent identifier'
        property :producer_pwd, as: :password, type: 'String', desc: 'producer agent password'
      end

    end

  end
end