# encoding: utf-8
require_relative 'item'

module Libis
  module Ingester

    class Division < Libis::Ingester::Item

      def filename=(f)
        self.properties[:name] = File.basename(f)
      end

      def divisions
        self.items.select { |item| item.is_a? Division }
      end

      def files
        self.items.select { |item| item.is_a? FileItem }
      end

      def all_divs
        divisions + divisions.select { |div| div.all_divs }.flatten
      end

      def all_files
        files + divisions.select { |div| div.all_files }.flatten
      end

    end

  end
end
