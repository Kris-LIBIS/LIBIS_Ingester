# encoding: utf-8

require 'libis/workflow/mongoid/base'

module Libis
  module Ingester

    class MetadataRecord
      include Libis::Workflow::Mongoid::Base

      embedded_in :item, class_name: Libis::Ingester::Item.to_s, inverse_of: :metadata

      field :format
      field :filepath
      field :data

    end

  end
end
