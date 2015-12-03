# encoding: utf-8
require 'yaml'
require 'libis/tools/extend/hash'

require 'libis/workflow/mongoid/base'
require 'libis/ingester'

module Libis
  module Ingester

    class IngestModel
      include Libis::Workflow::Mongoid::Base

      store_in collection: 'ingest_models'

      field :name
      field :description
      field :entity_type
      field :user_a
      field :user_b
      field :user_c
      field :status

      has_many :jobs, class_name: Libis::Ingester::Job.to_s, inverse_of: :ingest_model

      belongs_to :access_right, class_name: Libis::Ingester::AccessRight.to_s, inverse_of: nil
      belongs_to :retention_period, class_name: Libis::Ingester::RetentionPeriod.to_s, inverse_of: nil

      embeds_many :manifestations, class_name: Libis::Ingester::Manifestation.to_s

      validates :name, presence: true, allow_nil: false

      index({name: 1}, {unique: true})

    end

  end
end
