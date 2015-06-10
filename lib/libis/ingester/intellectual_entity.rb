# encoding: utf-8

require 'libis/workflow'

require_relative 'item'
require_relative 'file_item'
require_relative 'dir_item'

module Libis
  module Ingester

    class IntellectualEntity < Libis::Ingester::Item

      field :ingest_type, type: String, default: 'METS'

      def representations
        rep_list = Set.new
        files_recursive.each do |file|
          # noinspection RubyResolve
          manifestation = file.manifestation
          next unless manifestation
          rep_list << manifestation.name
        end
      end

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
