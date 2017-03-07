# encoding: utf-8

require 'libis-workflow'
require 'libis-ingester'

require_relative 'dir_collector'
module Libis
  module Ingester

    class DirListCollector < DirCollector

      description 'Parse a file and process the entries as listed.'

      help <<-STR
        This collector is derived from DirCollector and therefore works similarly. These are the differences:

        Files will not be parsed by reading a directory, but by reading the entries in a file. The file should contain
        the file names one per line. No other information should be in this file. As the files will be processed in the
        order they appear in the file, the 'sort' parameter is not used and frozen with false value.

        Subdirectories can be processed too, but they have to be listed in the list file too. The subdirectory should
        contain a list file with the same name if you want to process any files in the subdirectory too. The 'subdirs'
        parameter will be still used the same way as for DirCollector for processing the directory entries.

        Listing files in subdirectories in a parent directory's list file with the relative path, will process the files
        but without creating any hierarchy for the subdirectories and files will be added to the parent directory. You
        may use this feature for detailed control of your final structure, but things may become quite complex.
      STR

      parameter file_list: 'files.list',
                    description: 'Name of the file containing the file names'

      parameter sort: false, frozen: true

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
