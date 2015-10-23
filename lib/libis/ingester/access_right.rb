# encoding: utf-8
require 'libis/workflow/mongoid'

module Libis
  module Ingester

    class AccessRight
      include ::Libis::Workflow::Mongoid::Base
      store_in collection: 'access_rights'

      field :name, type: String
      field :ar_id, type: String
      field :ar_description, type: String
      field :watermark, type: String

      index({name: 1}, {unique: true})

      def info
        {
            name: self.name,
            ar_id: self.ar_id,
            ar_description: self.ar_description,
            watermark: self.watermark,
        }.cleanup
      end

    end

  end
end
