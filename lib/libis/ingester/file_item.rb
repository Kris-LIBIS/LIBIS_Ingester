# encoding: utf-8
require 'LIBIS_Workflow'

require_relative 'item'
require_relative 'manifestation'
module LIBIS
  module Ingester

    class FileItem < LIBIS::Ingester::Item
      include LIBIS::Workflow::FileItem

      has_one :manifestation, class_name: Manifestation.to_s, inverse_of: nil
    end

  end
end
