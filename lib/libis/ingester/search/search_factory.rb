# coding: utf-8

require_relative 'opac_search'
require_relative 'primo_search'
require_relative 'sharepoint_search'

module LIBIS
  module Ingester
    class SearchFactory
      def initialize(format)
        @search_class = self.class.const_get("LIBIS::Ingester::#{format}Search")
      rescue Exception => e
        puts e.message
        exit -1
      end

      def new_search
        @search_class.new
      end
    end
  end
end