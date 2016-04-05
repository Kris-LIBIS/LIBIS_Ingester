require 'double_bag_ftps'

module Libis
  module Ingester
    class FtpsService

      # Create FTP service
      # param [String] host
      # param [Integer] port
      # param [String] user
      # param [String] password
      def initialize(_host, _port, _user, _password)
        @host = _host
        @port = _port
        @user = _user
        @password = _password
        @ftp_service = DoubleBagFTPS.new
        connect
      end

      # Connect to FTP server
      def connect
        ftp_service.open_timeout = 10.0
        ftp_service.ftps_mode = DoubleBagFTPS::EXPLICIT
        ftp_service.connect(host, port)
        ftp_service.login user, password
        ftp_service.passive = true
        ftp_service.read_timeout = 5.0
      end

      # Disconnect from FTP server
      def disconnect
        ftp_service.close
      rescue
        # do nothing
      end

      # Change current directory on the FTP server
      # param [String] dir
      def chdir(dir)
        check do
          ftp_service.chdir(dir)
        end
      end

      # Get directory listing
      # param [String] dir
      # return [Array<String>]
      def ls(dir)
        check do
          ftp_service.nlst(dir)
        end
      end

      # Download a file
      # param [String] remote_path remote file path
      # param [String] local_path
      # param [Symbol] mode :binary or :text
      def get_file(remote_path, local_path, mode = :binary)
        check do
          mode == :binary ?
              ftp_service.getbinaryfile(remote_path, local_path) :
              ftp_service.gettextfile(remote_path, local_path)
        end
      end

      # Upload a file
      # param [String] remote_path remote file path
      # param [Object] data
      # param [Symbol] mode :binary or :text
      def put_file(remote_path, data, mode = :text)
        tempfile = Tempfile.new('ftp_upload')
        mode == :text ?
            data.each { |line| tempfile.puts(line) } :
            tempfile.write(data)
        tempfile.close
        check do
          mode == :text ?
              ftp_service.puttextfile(tempfile.path, remote_path) :
              ftp_service.putbinaryfile(tempfile.path, remote_path)
        end
        tempfile.unlink
      end

      # Check if remote path is a file (or a directory)
      # param [String] remote_path
      # return [Boolean] true if file, false if directory
      def is_file?(remote_path)
        ftp_service.size(remote_path).is_a?(Numeric) ? true : false rescue false
      end

      protected
      
      attr_accessor :host, :port, :user, :password

      # @return [DoubleBagFTPS]
      def ftp_service
        @ftp_service
      end

      # Tries to execute ftp commands; reconnects and tries again if connection timed out
      def check
        begin
          yield
        rescue Errno::ETIMEDOUT
          disconnect
          connect
          yield
        end
      end

    end
  end
end