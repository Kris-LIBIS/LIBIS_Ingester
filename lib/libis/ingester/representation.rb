# encoding: utf-8

require_relative 'item'
require_relative 'representation_info'
require_relative 'file_item'
require_relative 'dir_item'
require_relative 'division'

module Libis
  module Ingester

    class Representation < Libis::Ingester::Item

      field :name
      field :label
      field :pid

      belongs_to :representation_info, class_name: ::Libis::Ingester::RepresentationInfo.to_s, inverse_of: nil

      def files
        self.items.select { |item| item.is_a? FileItem }
      end

      def divisions
        self.items.select { |item| item.is_a? Division }
      end

      def all_files_recursive
        files + divisions.select { |div| div.all_files }.flatten
      end

      # noinspection RubyResolve
      def to_hash
        super.merge(self.representation_info.to_hash)
      end

    end

  end
end
