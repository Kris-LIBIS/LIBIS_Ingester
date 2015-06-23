# encoding: utf-8


module Libis
  module Ingester

    class RepresentationInfo
      include Libis::Workflow::Mongoid::Base
      store_in collection: 'representation_infos'

      field :name
      field :label
      field :preservation_type
      field :usage_type
      field :representation_code
      field :entity_type
      field :user_a
      field :user_b
      field :user_c

      validates_presence_of :name
      validates_uniqueness_of :name

      def info
        {
            name: self.name,
            label: self.label,
            preservation_type: self.preservation_type,
            usage_type: self.usage_type,
            representation_code: self.representation_code,
            entity_type: self.entity_type,
            user_a: self.user_a,
            user_b: self.user_b,
            user_c: self.user_c,
        }
      end

    end

  end
end
