# encoding: utf-8
require 'libis/workflow'

require 'libis/ingester'

module Libis
  module Ingester

    class DirItem < ::Libis::Ingester::Item
      include Libis::Workflow::Base::DirItem

      def files
        self.items.select { |item| item.is_a? FileItem }
      end

      def dirs
        self.items.select { |item| item.is_a? DirItem }
      end

      def all_files
        files + dirs.select { |dir| dir.all_files }.flatten
      end

    end

  end
end
