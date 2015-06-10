# encoding: utf-8
require 'yaml'
require 'libis/tools/extend/hash'

module Libis
  module Ingester

    require 'libis/workflow/mongoid/base'

    class IngestModel
      include Libis::Workflow::Mongoid::Base

      class ManifestationInfo
        include Libis::Workflow::Mongoid::Base

        field :name
        field :target_format
        field :options, type: Hash
        field :priority, type: Integer, default: 0
        embeds_one :access_right_info

        validates_presence_of :name
        validates_uniqueness_of :name

        def info
          {
              name: self.name,
              target_format: self.target_format,
              options: self.options,
              priority: self.priority,
              access_right: (self.access_right_info.info rescue nil)
          }.cleanup
        end
      end

      field :name
      field :description
      field :producer
      field :material_flow
      field :group
      field :formats, type: Array

      embeds_many :manifestation_infos

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
            manifestations: (self.manifestation_infos.map(&:info) rescue nil),
        }.cleanup
      end

    end

  end
end
