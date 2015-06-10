# encoding: utf-8
require 'libis/workflow/mongoid'

module Libis
  module Ingester

    class AccessRight
      include ::Libis::Workflow::Mongoid::Base

      field :id, type: String
      field :name, type: String
      field :watermark, type: String

      def info
        {
            id: self.id,
            name: self.name,
            watermark: self.watermark,
        }.cleanup
      end

    end

  end
end
