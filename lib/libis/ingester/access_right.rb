# encoding: utf-8
require 'libis/workflow/mongoid'

module Libis
  module Ingester

    class AccessRight
      include ::Libis::Workflow::Mongoid::Base

      field :name, type: String
      field :ar_id, type: String
      field :watermark, type: String

      def info
        {
            name: self.name,
            ar_id: self.ar_id,
            watermark: self.watermark,
        }.cleanup
      end

    end

  end
end
