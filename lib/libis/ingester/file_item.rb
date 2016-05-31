# encoding: utf-8
require 'libis/workflow'

require_relative 'item'

module Libis
  module Ingester

    class FileItem < Libis::Ingester::Item
      include Libis::Workflow::Base::FileItem

      field :entity_type
      field :pid

      def name
        self.properties['name'] || File.basename(self.filename, '.*')
      end

    end

  end
end
