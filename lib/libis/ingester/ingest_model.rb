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
      field :producer
      field :material_flow
      field :formats, type: Array
      field :group_match
      field :group_label
      field :group_file
      field :entity_type
      field :user_a
      field :user_b
      field :user_c
      field :status
      field :access_right
      field :retention_period

      embeds_many :manifestations, class_name: Libis::Ingester::Manifestation.to_s
      belongs_to :organization, class_name: Libis::Ingester::Organization.to_s, inverse_of: :ingest_models

      validates :producer, presence: true, allow_nil: false
      validates :name, presence: true, allow_nil: false

      index({producer: 1, name: 1}, {unique: true})
      index({producer: 1, name: 1, formats: 1}, {unique: true})

      def info
        {
            name: self.name,
            description: self.description,
            producer: self.producer,
            material_flow: self.material_flow,
            formats: self.formats,
            group_match: self.group_match,
            group_label: self.group_label,
            group_file: self.group_file,
            entity_type: self.entity_type,
            retention_period: self.retention_period,
            manifestations: (self.manifestations.map(&:info) rescue nil),
        }.cleanup
      end

    end

  end
end
