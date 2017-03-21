require_relative 'organization'
require_relative 'job'

module Libis::Ingester::API::Representer
  class OrganizationDetailRepresenter < OrganizationRepresenter

    attributes do
      property :code, type: String, desc: 'institution code'
      property :material_flow, type: JSON, desc: 'supported material flows'
      property :ingest_dir, type: String, desc: 'directory where the SIPs will be uploaded'

      nested :producer do
        property :producer_id, as: :id, type: 'String', desc: 'producer identifier'
        property :producer_agent, as: :agent, type: 'String', desc: 'producer agent identifier'
        property :producer_pwd, as: :password, type: 'String', desc: 'producer agent password'
      end

    end

    has_many :jobs,
             class: Libis::Ingester::Job,
             decorator: JobRepresenter,
             populator: ::Representable::FindOrInstantiate

    link :jobs do |opts|
      "#{self.class.self_url(opts)}/#{represented.id}/jobs"
    end

  end
end