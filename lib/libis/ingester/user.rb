# encoding: utf-8
require 'digest'

require 'libis/workflow/mongoid/base'
require 'libis/tools/checksum'
require 'libis/ingester'

module Libis
  module Ingester

    class User

      include Libis::Workflow::Mongoid::Base

      store_in collection: 'users'

      field :name
      field :password_hash
      field :role, type: Symbol, default: :submitter

      index({name: 1}, {unique: true, name: 'by_name'})

      has_and_belongs_to_many :organizations, class_name: Libis::Ingester::Organization.to_s,
                              inverse_of: :users, order: :name.asc
      index({organization_id: 1, name: 1}, {name: 'by_organization'})

      def self.from_hash(hash)
        # noinspection RubyResolve
        self.create_from_hash(hash, [:name]) do |item, cfg|
          item.organizations.clear
          (cfg.delete('organizations') || []).each do |org_name|
            item.organizations << Libis::Ingester::Organization.from_hash(name: org_name)
          end
        end
      end

      def authenticate(password)
        return true if self.password_hash.blank? && password.blank?
        self.class.get_password_hash(password) == self.password_hash
      end

      def self.authenticate(name, password)
        user = User.find_by(name: name)
        return user if user && user.authenticate(password)
        nil
      end

      def password=(password)
        self.password_hash = self.class.get_password_hash(password)
        nil
      end

      def password
        self.password_hash
      end

      def self.get_password_hash(password)
        md5 = Libis::Tools::Checksum.hexdigest('LibisIngesterUser' + password, :MD5)
        Libis::Tools::Checksum.hexdigest(md5 + password, :SHA256)
      end

    end

  end
end
