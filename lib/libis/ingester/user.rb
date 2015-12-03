# encoding: utf-8
require 'digest'

require 'libis/workflow/mongoid/base'
require 'mongoid/enum'

require 'libis/ingester'

module Libis
  module Ingester

    class User

      include Libis::Workflow::Mongoid::Base
      include Mongoid::Enum

      store_in collection: 'users'

      field :name
      field :user_id
      field :password_hash
      enum :role, [:submitter, :admin], default: :submitter

      index({user_id: 1}, {unique: true})

      has_and_belongs_to_many :organizations, class_name: Libis::Ingester::Organization.to_s, inverse_of: :users,
                              order: :name.asc

      def self.authenticate(name, password)
        user = User.find_by(name: name)
        return user if user && get_password_hash(password) == user.password
        nil
      end

      def password=(password)
        self.password_hash = get_password_hash(password)
        nil
      end

      def password
        self.password_hash
      end

      private

      def self.get_password_hash(password)
        Digest('SHA256').base64digest(password)
      end

    end

  end
end
