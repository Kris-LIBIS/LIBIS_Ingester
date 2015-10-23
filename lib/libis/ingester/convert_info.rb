require 'libis/ingester'

require 'libis/workflow/mongoid/base'
module Libis
  module Ingester

    class ConvertInfo
      include Libis::Workflow::Mongoid::Base

      field :generator
      field :source_formats, type: Array
      field :target_format
      field :options, type: Hash
      field :from_manifestation

      embedded_in :manifestation, class_name: Libis::Ingester::Manifestation.to_s

      def info
        {
            from_manifestation: self.from_manifestation,
            generator: self.generator,
            source_formats: self.source_formats,
            target_format: self.target_format,
            options: self.options || {},
        }.cleanup
      end

    end

  end
end
