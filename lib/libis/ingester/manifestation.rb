# encoding: utf-8

require 'libis/workflow/mongoid/base'

module LIBIS
  module Ingester

    class Manifestation
      include LIBIS::Workflow::Mongoid::Base

      field :name
      field :object_type
      field :preservation_type
      field :usage_type
      field :representation_code

    end

  end
end
