require_relative 'organization'

module Libis::Ingester::API::Representer
  class JobDetailRepresenter < JobRepresenter

    attributes do
      property :input, type: JSON, desc: 'input parameter values'
      property :material_flow, type: String, desc: 'name of the material flow'
      property :c_at, as: :created_at, writeable: false, type: DateTime, desc: 'Date when the organization was created'

    end

  end
end