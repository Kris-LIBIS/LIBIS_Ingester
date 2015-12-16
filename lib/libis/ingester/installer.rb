require 'libis-ingester'
require 'libis-tools'

module Libis
  module Ingester

    # noinspection RubyResolve
    class Installer

      attr_accessor :config, :database

      def initialize(config_file)

        @config = Installer.load_config(config_file)

        raise RuntimeError, "Configuration file '#{config_file}' not found." unless @config

        raise RuntimeError, "Missing section 'config' in site config." unless @config.config

        ::Libis::Ingester.configure do |cfg|
          cfg.workdir = @config.config.workdir || '/tmp'
          cfg.base_url = @config.config.base_url || 'http://depot.lias.be'
          cfg.pds_url = @config.config.pds_url || 'https://pds.libis.be'

        end

        if @config.ingester && @config.ingester.task_dir
          ::Libis::Ingester::Config.require_all(@config.ingester.task_dir)
        end

      end

      def create_database

        raise RuntimeError, "Missing section 'database' in site config." unless @config.database

        @database = ::Libis::Ingester::Database.new(
            (@config.database.config_file || File.join(Libis::Ingester::ROOT_DIR, 'mongoid.yml')),
            (@config.database.env || :test)
        )

        ::Libis::Ingester::Workflow.each { |wf| wf.destroy }

        @database.clear.setup.seed
        @database.seed(@config.database.seed_dir) if @config.database.seed_dir && Dir.exist?(@config.database.seed_dir)
        @database.seed(@config.seed.to_h) if @config.seed

        @database

      end

      def self.load_config(config_file)

        raise RuntimeError, "Configuration file '#{config_file}' not found." unless File.exist?(config_file)

        config = Libis::Tools::ConfigFile.new({}, preserve_original_keys: false)
        config << config_file

        config

      end

    end

  end
end
