# encoding: utf-8
require_relative 'item'
require_relative 'file_item'
require_relative 'mets_division'

module LIBIS
  module Ingester

    class Collection < Item

      def filename=(f)
        self.properties[:name] = File.basename(f)
      end

      def collections
        self.items.select { |item| item.is_a? Collection }
      end

      def divisions
        self.items.select { |item| item.is_a? MetsDivision }
      end

      def files
        self.items.select { |item| item.is_a? FileItem }
      end

    end

  end
end
