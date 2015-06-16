# encoding: utf-8
require_relative 'item'
require_relative 'intellectual_entity'

module Libis
  module Ingester

    class Collection < Item

      def filename=(f)
        self.properties[:name] = File.basename(f)
      end

      def collections
        self.items.select { |item| item.is_a? Collection }
      end

      def intellectual_entities
        self.items.select { |item| item.is_a? IntellectualEntity }
      end

    end

  end
end
