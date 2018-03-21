# encoding: utf-8
require_relative 'item'
require_relative 'intellectual_entity'

module Libis
  module Ingester

    class Collection < ::Libis::Ingester::Item

      field :navigate, type: Boolean, default: true
      field :publish, type: Boolean, default: false
      field :description, type: String
      field :external_system, type: String
      field :external_id, type: String

      def filename=(f)
        self.properties['name'] = File.basename(f)
      end

      def pid
        self.properties[:collection_id] ? "col#{this.properties[:collection_id]}" : nil
      end

      def collections
        self.items.select { |item| item.is_a? ::Libis::Ingester::Collection }
      end

      def intellectual_entities
        self.items.select { |item| item.is_a? ::Libis::Ingester::IntellectualEntity }
      end

    end

  end
end
