# encoding: utf-8
require 'LIBIS_Workflow'

require_relative 'item'
require_relative 'manifestation'
module LIBIS
  module Ingester

    class DirItem < LIBIS::Ingester::Item
      include LIBIS::Workflow::DirItem

    end

  end
end
