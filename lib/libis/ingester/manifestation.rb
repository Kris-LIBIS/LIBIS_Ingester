require 'libis/ingester'

require 'libis/workflow/mongoid/base'
module Libis
  module Ingester

    class Manifestation
      include Libis::Workflow::Mongoid::Base

      field :name
      field :label
      field :optional, type: Boolean, default: false

      belongs_to :access_right, class_name: Libis::Ingester::AccessRight.to_s, inverse_of: nil
      belongs_to :representation_info, class_name: Libis::Ingester::RepresentationInfo.to_s, inverse_of: nil

      embeds_many :convert_infos, class_name: Libis::Ingester::ConvertInfo.to_s

      embedded_in :ingest_model, class_name: Libis::Ingester::IngestModel.to_s

      validates_presence_of :name
      validates_uniqueness_of :name

      def self.from_hash(hash)
        # noinspection RubyResolve
        self.create_from_hash(hash, [:name]) do |item, cfg|
          item.access_right = Libis::Ingester::AccessRight.from_hash(name: cfg.delete('access_right'))
          item.representation_info = Libis::Ingester::RepresentationInfo.from_hash(name: cfg.delete('representation'))
          item.convert_infos.clear
          (cfg.delete('convert') || []).each do |cv_cfg|
            item.convert_infos << Libis::Ingester::ConvertInfo.from_hash(cv_cfg)
          end
        end
      end

    end
  end

end
