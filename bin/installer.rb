require 'libis-ingester'

module Libis
  module Ingester

    class Installer

      attr_accessor :config_file

      def initialize(config_file)
        @config_file = Libis::Tools::ConfigFile.new
        @config_file << config_file if File.exist?(config_file)
      end

      def create_database

      end


    end

  end
end