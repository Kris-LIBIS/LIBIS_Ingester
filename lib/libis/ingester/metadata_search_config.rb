require 'libis/ingester'
require 'mongoid/enum'

require 'libis/workflow/mongoid/base'
module Libis
  module Ingester

    class MetadataSearchConfig
      include Libis::Workflow::Mongoid::Base

      field :name
      enum :cms_type, [:alma, :scope]
      field :url
      field :library
      enum :mapping, %w'Kuleuven Scope Flandrica'
      field :field

      def self.from_hash(hash)
        self.create_from_hash(hash.cleanup, [])
      end

    end

  end
end
