# encoding: utf-8
require 'libis/workflow'

require_relative 'item'

module Libis
  module Ingester

    class FileItem < Libis::Ingester::Item
      include Libis::Workflow::Base::FileItem

      field :entity_type
      field :pid

    end

  end
end
