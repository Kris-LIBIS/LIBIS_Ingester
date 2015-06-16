require_relative 'access_right'

require 'libis/workflow/mongoid/base'
module Libis
  module Ingester

    class Manifestation
      include Libis::Workflow::Mongoid::Base

      field :name
      field :target_format
      field :options, type: Hash
      field :generator
      has_one :access_right, class_name: ::Libis::Ingester::AccessRight.to_s, inverse_of: nil

      validates_presence_of :name
      validates_uniqueness_of :name

      def info
        {
            name: self.name,
            target_format: self.target_format,
            options: self.options,
            generator: self.generator,
            access_right: (self.access_right.info rescue nil)
        }.cleanup
      end
    end

  end
end
