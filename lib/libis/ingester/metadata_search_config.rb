require 'libis/ingester'

require 'libis/workflow/mongoid/base'
module Libis
  module Ingester

    class MetadataSearchConfig
      include Libis::Workflow::Mongoid::Base

      field :url
      field :library
      field :mapping
      field :field

      def self.from_hash(hash)
        self.create_from_hash(hash.cleanup, [])
      end

    end

  end
end
