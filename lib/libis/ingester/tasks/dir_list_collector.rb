# encoding: utf-8

require 'libis-workflow'
require 'libis-ingester'

require_relative 'dir_collector'
module Libis
  module Ingester

    class DirListCollector < DirCollector

      parameter file_list: 'files.list',
                description: 'Name of the file containing the file names'

      protected

      def collect(item, dir)
        return unless File.exist?(dir)
        return unless File.directory?(dir)
        dirlist = File.join(dir, 'files.list')
        return unless File.exist?(dirlist)
        debug 'Collecting files from \'%s\'', dirlist
        add_files(item, dir, File.readlines(dirlist))
        item.save!
      end

    end
  end
end
