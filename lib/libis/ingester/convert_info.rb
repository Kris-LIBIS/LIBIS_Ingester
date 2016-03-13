require 'libis/ingester'

require 'libis/workflow/mongoid/base'
module Libis
  module Ingester

    class ConvertInfo
      include Libis::Workflow::Mongoid::Base

      field :generator
      field :source_formats, type: Array
      field :target_format
      field :options, type: Hash, default: -> { Hash.new }
      field :from_manifestation

      embedded_in :manifestation, class_name: Libis::Ingester::Manifestation.to_s
    end

  end
end
