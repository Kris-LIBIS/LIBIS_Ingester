# encoding: utf-8
require 'libis/workflow/mongoid/base'

require 'libis/ingester'

module Libis
  module Ingester

    class Organization
      include Libis::Workflow::Mongoid::Base
      store_in collection: 'organizations'

      field :name
      field :code
      field :producer_id
      field :producer_agent
      field :producer_pwd
      field :material_flow
      field :ingest_dir

      index({name: 1}, {unique: 1})

      has_and_belongs_to_many :users, class_name: Libis::Ingester::User.to_s, inverse_of: :organizations,
                              order: :name.asc
      has_many :jobs, class_name: Libis::Ingester::Job.to_s, inverse_of: :organization,
               dependent: :destroy, autosave: true, order: :name.asc

      def producer
        {
            id: self.producer_id,
            agent: self.producer_agent,
            password: self.producer_pwd,
            institution: self.code
        }

      end
    end

  end
end
