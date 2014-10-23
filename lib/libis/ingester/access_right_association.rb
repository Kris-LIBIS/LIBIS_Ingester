# encoding: utf-8

require 'libis/workflow/mongoid/base'

require_relative 'access_right'
require_relative 'access_right_model'
require_relative 'manifestation'
module LIBIS
  module Ingester

    # noinspection RailsParamDefResolve
    class AccessRightAssociation
      include ::LIBIS::Workflow::Mongoid::Base

      belongs_to :access_right_model, inverse_of: :association, class_name: 'LIBIS::Ingester::AccessRight'
      belongs_to :access_right, class_name: 'LIBIS::Ingester::AccessRight'

      belongs_to :manifestation, class_name: 'LIBIS::Ingester::Manifestation'

    end

  end
end
