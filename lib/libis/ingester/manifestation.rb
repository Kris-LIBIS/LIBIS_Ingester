# encoding: utf-8

require 'libis/workflow/mongoid/base'

module Libis
  module Ingester

    class Manifestation
      include Libis::Workflow::Mongoid::Base

      field :name
      field :object_type
      field :preservation_type
      field :usage_type
      field :representation_code

      validates_presence_of :name
      validates_uniqueness_of :name

      def info
        {
            name: self.name,
            object_type: self.object_type,
            preservation_type: self.preservation_type,
            usage_type: self.usage_type,
            representation_code: self.representation_code
        }
      end

    end

  end
end
