# encoding: utf-8
require 'libis/workflow'

require_relative 'item'

module Libis
  module Ingester

    class FileItem < Libis::Ingester::Item
      include Libis::Workflow::Base::FileItem

      field :entity_type

      def info
        super.merge(self.properties.select {|k,_| k.to_s =~ /^checksum_/ }.map{|k,v| [k.to_sym, v]})
      end

    end

  end
end
