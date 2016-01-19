# encoding: utf-8
require 'libis/workflow'

require_relative 'item'

module Libis
  module Ingester

    class FileItem < Libis::Ingester::Item
      include Libis::Workflow::Base::FileItem

      field :entity_type

      def info
        super.merge(self.properties.inject({}) {|h,x| x.first.to_s =~ /^checksum_(.*)$/ ? h["checksum_#{$1.upcase}".to_sym] = x.last : nil; h })
      end

    end

  end
end
