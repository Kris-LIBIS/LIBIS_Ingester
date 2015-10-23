require 'libis/ingester'

require 'libis/workflow/mongoid/base'
module Libis
  module Ingester

    class Manifestation
      include Libis::Workflow::Mongoid::Base

      field :name
      field :label

      belongs_to :access_right, class_name: Libis::Ingester::AccessRight.to_s, inverse_of: nil
      belongs_to :representation_info, class_name: Libis::Ingester::RepresentationInfo.to_s, inverse_of: nil

      embeds_many :convert_infos, class_name: Libis::Ingester::ConvertInfo.to_s

      embedded_in :ingest_model, class_name: Libis::Ingester::IngestModel.to_s

      validates_presence_of :name
      validates_uniqueness_of :name

      def info
        {
            name: self.name,
            label: self.label,
            access_right: self.access_right && self.access_right.info,
            representation_info: self.representation_info && self.representation_info.info,
            convert_infos: self.convert_infos.map { |ci| ci.info }
        }.cleanup
      end
    end

  end
end
