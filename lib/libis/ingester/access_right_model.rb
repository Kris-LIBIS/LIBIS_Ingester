# encoding: utf-8

require 'libis/workflow/mongoid/base'

require_relative 'access_right'
module LIBIS
  module Ingester
    class AccessRightModel
      include ::LIBIS::Workflow::Mongoid::Base

      field :name
      has_many :access_rights, inverse_of: nil

    end
  end
end
