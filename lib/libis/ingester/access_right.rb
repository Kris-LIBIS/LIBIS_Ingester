# encoding: utf-8

require 'libis/workflow/mongoid/base'
require_relative 'access_right_association'

module LIBIS
  module Ingester
    class AccessRight
      include ::LIBIS::Workflow::Mongoid::Base

      field :ar_type, type: String
      field :ar_info, type: Hash
      field :negate, type: Boolean, default: false
      field :mid, type: String

      def info
        {
            ar_type: self.ar_type,
            ar_info: self.ar_info,
            negate: self.negate,
            mid: self.mid,
        }
      end
    end
  end
end
