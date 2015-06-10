# encoding: utf-8
require 'libis/workflow'

require_relative 'item'
require_relative 'file_item'

module Libis
  module Ingester

    class DirItem < Libis::Ingester::Item
      include Libis::Workflow::DirItem

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
