# encoding: utf-8
require 'libis/workflow'

require_relative 'item'
require_relative 'manifestation'

module Libis
  module Ingester

    class FileItem < Libis::Ingester::Item
      include Libis::Workflow::FileItem

      has_one :manifestation, class_name: Manifestation.to_s, inverse_of: nil
    end

  end
end
