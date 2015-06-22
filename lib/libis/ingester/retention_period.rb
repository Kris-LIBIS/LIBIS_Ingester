# encoding: utf-8
require 'libis/workflow/mongoid'

module Libis
  module Ingester

    class RetentionPeriod
      include ::Libis::Workflow::Mongoid::Base
      store_in collection: 'retention_periods'

      field :name, type: String
      field :rp_id, type: String

      def info
        {
            name: self.name,
            rp_id: self.rp_id,
        }.cleanup
      end

    end

  end
end
