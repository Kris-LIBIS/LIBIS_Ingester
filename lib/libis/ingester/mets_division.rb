# encoding: utf-8
require_relative 'item'

module Libis
  module Ingester

    class MetsDivision < Libis::Ingester::Item

      def filename=(f)
        self.properties[:name] = File.basename(f)
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
