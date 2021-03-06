require 'libis/ingester'

require 'libis/workflow/mongoid/base'
module Libis
  module Ingester

    class ConvertInfo
      include Libis::Workflow::Mongoid::Base

      field :generator
      field :generated_file
      field :source_formats, type: Array
      field :source_files, type: String
      field :target_format
      field :options, type: Array
      field :from_manifestation
      field :copy_file, type: Boolean
      field :properties, type: Hash

      embedded_in :manifestation, class_name: Libis::Ingester::Manifestation.to_s

      def self.from_hash(hash)
        self.create_from_hash(hash.cleanup, [])
      end

    end

  end
end
