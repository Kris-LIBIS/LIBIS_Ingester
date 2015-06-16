# encoding: utf-8

require 'libis/workflow'

require_relative 'item'
require_relative 'representation'
require_relative 'dir_item'

module Libis
  module Ingester

    class IntellectualEntity < Libis::Ingester::Item
      include Libis::Workflow::Mongoid::Base

      field :ingest_type, type: String, default: 'METS'

      def representations
        self.items.select { |item| item.is_a? ::Libis::Ingester::Representation }
      end

    end

  end
end
