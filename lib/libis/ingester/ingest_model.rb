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
      field :identifier

      has_many :jobs, class_name: Libis::Ingester::Job.to_s, inverse_of: :ingest_model,
               dependent: :restrict, autosave: true, order: :name.asc

      belongs_to :access_right, class_name: Libis::Ingester::AccessRight.to_s, inverse_of: nil
      belongs_to :retention_period, class_name: Libis::Ingester::RetentionPeriod.to_s, inverse_of: nil

      embeds_many :manifestations, class_name: Libis::Ingester::Manifestation.to_s

      validates :name, presence: true, allow_nil: false

      index({name: 1}, {unique: true, name: 'by_name'})

      def self.from_hash(hash)
        # noinspection RubyResolve
        self.create_from_hash(hash, [:name]) do |item, cfg|
          item.access_right = Libis::Ingester::AccessRight.from_hash(name: cfg.delete('access_right'))
          item.retention_period = Libis::Ingester::RetentionPeriod.from_hash(name: cfg.delete('retention_period'))
          item.manifestations.clear
          (cfg.delete('manifestations') || []).each do |mf_cfg|
            item.manifestations << Libis::Ingester::Manifestation.from_hash(mf_cfg)
          end
        end
      end

      # noinspection RubyResolve
      def to_hash
        result = super
        result[:access_right_id] = self.access_right.ar_id if self.access_right
        result[:retention_period_id] = self.retention_period.rp_id if self.retention_period
        result[:manifestations] = self.manifestations.map(&:to_hash)
        result.cleanup
      end

    end

  end
end
