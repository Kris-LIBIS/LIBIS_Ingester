# encoding: utf-8
require 'libis/workflow/mongoid/base'
# require 'mongoid/enum'

require 'libis/ingester'

module Libis
  module Ingester

    class Account
      include Libis::Workflow::Mongoid::Base
      # include Mongoid::Enum
      store_in collection: 'accounts'

      field :name
      # enum :role, [:viewer, :producer, :admin]
      field :user_id
      field :user_name
      field :password

      ROLE = [:viewer, :producer, :admin]
      field :role, type: Symbol, default: ROLE.first

      index({user_id: 1}, {unique: true})

      belongs_to :organization, class_name: Libis::Ingester::Organization.to_s, inverse_of: :accounts

      def role
        self.read_attribute(:role)
      end

      def role=(value)
        write_attribute(:role, value && value.to_sym || nil)
      end

      ROLE.each do |r|
        scope r, -> { where(role: ROLE.find_index(r)) }
        class_eval "def #{r}!() update_attributes!(role: :#{r}) end"
        class_eval "def #{r}?() read_attribute(:role) == #{r} end"
      end
    end

  end
end
