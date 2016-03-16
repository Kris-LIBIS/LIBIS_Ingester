# encoding: utf-8
require 'digest'

require 'libis/workflow/mongoid/base'
require 'mongoid/attributes/dynamic'
require 'libis/tools/checksum'
require 'libis/ingester'

module Libis
  module Ingester

    class DomainStorage

      include Libis::Workflow::Mongoid::Base
      include ::Mongoid::Timestamps::Updated::Short

      store_in collection: 'domain_storage'

      field :domain
      field :name
      field :data, type: Hash, default: -> { Hash.new }

      index({domain: 1, name: 1}, {unique: true, name: 'by_domain_name'})

      protected

      def volatile_attributes
        super + 'u_at'
      end

    end

  end
end
