# encoding: utf-8
require 'libis/workflow/mongoid/base'

require 'libis/ingester'

module Libis
  module Ingester

    class Organization
      include Libis::Workflow::Mongoid::Base
      store_in collection: 'organizations'

      field :name
      field :code

      has_many :ingest_models, class_name: Libis::Ingester::IngestModel.to_s, inverse_of: :organization,
               dependent: :destroy, autosave: true, order: :created_at.asc
      has_many :accounts, class_name: Libis::Ingester::Account.to_s, inverse_of: :organization,
               dependent: :destroy, autosave: true, order: :created_at.asc

    end

  end
end
