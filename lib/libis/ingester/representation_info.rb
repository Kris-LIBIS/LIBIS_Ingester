# encoding: utf-8


module Libis
  module Ingester

    class RepresentationInfo
      include Libis::Workflow::Mongoid::Base
      store_in collection: 'representation_infos'

      field :name
      field :preservation_type
      field :usage_type
      field :representation_code
      field :entity_type
      field :user_a
      field :user_b
      field :user_c

      index({name: 1}, {unique: true})

    end

  end
end
