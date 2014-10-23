# encoding: utf-8

require 'libis/workflow/mongoid/base'

module LIBIS
  module Ingester

    class MetadataRecord
      include LIBIS::Workflow::Mongoid::Base

      embedded_in :item, class_name: 'LIBIS::Ingester::Item', inverse_of: :metadata

      field :format
      field :filepath
      field :data

    end

  end
end
