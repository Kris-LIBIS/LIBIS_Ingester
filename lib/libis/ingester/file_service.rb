require 'fileutils'

module Libis
  module Ingester
    class FileService

      # Create File service
      # param [String] root the root folder for the file service
      def initialize(_root)
        @root = _root
      end

      # Get directory listing
      # param [String] dir
      # return [Array<String>]
      def ls(dir)
        Dir(abspath(dir)).map do |entry|
          (File.file?(abspath(dir, entry)) || entry =~ /^\.+$/) ? nil : File.join(dir, entry)
        end.delete_if { |x| x.nil? }
      end

      # Download a file
      # param [String] remote_path remote file path
      # param [String] local_path
      # param [Symbol] mode :binary or :text
      def get_file(remote_path, local_path, mode = :binary)
        FileUtils.cp abspath(remote_path), local_path, preserve: (mode == :binary)
      end

      # Upload a file
      # param [String] remote_path remote file path
      # param [Object] data
      # param [Symbol] mode :binary or :text
      def put_file(remote_path, data, mode = :text)
        File.open abspath(remote_path), 'w' + (mode == :binary ? 'b' : 't') do |f|
          f.write(data)
        end
      end

      # Delete a file
      # param [String] remote_path remote file path
      def del_file(remote_path)
        FileUtils.rm([abspath(remote_path)])
      end

      # Delete a directory
      # param [String] remote_path remote directory
      def del_dir(remote_path)
        FileUtils.rm([abspath(remote_path)])
      end

      # Delete a directory
      # param [String] remote_path remote directory
      def del_tree(remote_path)
        FileUtils.rmtree [abspath(remote_path)]
      end

      def exist?(remote_path)
        File.exist? abspath(remote_path)
      end

      # Check if remote path is a file (or a directory)
      # param [String] remote_path
      # return [Boolean] true if file, false if directory
      def is_file?(remote_path)
        File.file? abspath(remote_path)
      end

      protected

      attr_accessor :root

      def abspath(dir, file = '')
        File.join(@root, dir, file)
      end

      def relpath(path)
        require 'pathname'
        Pathname(path).relative_path_from(Pathname(@root)).to_s
      end

    end
  end
end