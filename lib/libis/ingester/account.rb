# encoding: utf-8
require 'libis/workflow/mongoid/base'
require 'mongoid/enum'

require 'libis/ingester'

module Libis
  module Ingester

    class Account
      include Libis::Workflow::Mongoid::Base
      include Mongoid::Enum
      store_in collection: 'accounts'

      field :name
      enum :role, [:viewer, :producer, :admin]
      field :user_id
      field :user_name
      field :password

      belongs_to :organization, class_name: Libis::Ingester::Organization.to_s, inverse_of: :accounts
    end

  end
end
