# encoding: utf-8
require 'yaml'
require 'libis/tools/extend/hash'

require 'libis/workflow/mongoid/base'
require_relative 'manifestation'

module Libis
  module Ingester

    class IngestModel
      include Libis::Workflow::Mongoid::Base

      field :name
      field :description
      field :producer
      field :material_flow
      field :group
      field :formats, type: Array

      embeds_many :manifestations, class_name: ::Libis::Ingester::Manifestation.to_s

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
            group: self.group,
            formats: self.formats,
            manifestations: (self.manifestations.map(&:info) rescue nil),
        }.cleanup
      end

    end

  end
end
