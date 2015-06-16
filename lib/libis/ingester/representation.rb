# encoding: utf-8

require_relative 'item'
require_relative 'representation_info'

module Libis
  module Ingester

    class Representation < Libis::Ingester::Item

      has_one :representation_info, class_name: ::Libis::Ingester::RepresentationInfo.to_s, inverse_of: nil

      def files
        self.items.select { |item| item.is_a? FileItem }
      end

      def dirs
        self.items.select { |item| item.is_a? DirItem }
      end

      def files_recursive
        files + dirs.select { |dir| dir.files_recursive }.flatten
      end


    end

  end
end
