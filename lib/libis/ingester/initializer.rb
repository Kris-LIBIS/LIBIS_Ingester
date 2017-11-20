require 'libis-ingester'
require 'libis-tools'
require 'libis-format'
require 'libis/tools/extend/hash'

require 'sidekiq'
require 'sidekiq/api'

require 'singleton'

module Libis
  module Ingester

    # noinspection RubyResolve
    class Initializer
      include Singleton

      attr_accessor :config, :database

      def initialize
        @config = nil
        @database = nil
      end

      def self.init(config_file)
        initializer = self.instance
        initializer.configure(config_file)
        initializer.database
        initializer.sidekiq
        initializer
      end

      def configure(config_file)

        @config = Initializer.load_config(config_file)

        raise RuntimeError, "Configuration file '#{config_file}' not found." unless @config

        raise RuntimeError, "Missing section 'config' in site config." unless @config.config

        ::Libis::Ingester.configure do |cfg|
          @config.config.each do |key, value|
            cfg.send("#{key}=", value)
          end
        end

        if @config.ingester && @config.ingester.task_dir
          ::Libis::Ingester::Config.require_all(@config.ingester.task_dir)
        end

        if @config.format_config
          Libis::Format::TypeDatabase.instance.load_types(@config.format_config.type_database) if @config.format_config.type_database
          Libis::Format::Tools::Fido.add_format(@config.format_config.fido_formats) if @config.format_config.fido_formats
        end

        self
      end

      def database

        return @database if @database

        raise RuntimeError, "Missing section 'database' in site config." unless @config && @config.database

        @database = ::Libis::Ingester::Database.new(
            (@config.database.config_file || File.join(Libis::Ingester::ROOT_DIR, 'mongoid.yml')),
            (@config.database.env || :test)
        )

      end

      def sidekiq

        return @sidekiq if @sidekiq

        raise RuntimeError, 'Missing sidekiq section in configuration.' unless @config && @config.sidekiq

        id = (@config.sidekiq.namespace.gsub(/\s/, '') || 'Ingester' rescue 'Ingester')

        Sidekiq.configure_client do |config|
          config.redis = {
              url: @config.sidekiq.redis_url,
              namespace: @config.sidekiq.namespace,
              id: "#{id}Client"
          }.cleanup
        end

        Sidekiq.configure_server do |config|
          config.redis = {
              url: @config.sidekiq.redis_url,
              namespace: @config.sidekiq.namespace,
              id: "#{id}Server"
          }.cleanup
        end

        @sidekiq = Sidekiq::Client.new

      end

      def seed_database

        raise RuntimeError, 'Database not initialized.' unless @database

        sources = []
        sources << @config.database.seed_dir if @config.database.seed_dir && Dir.exist?(@config.database.seed_dir)
        sources << @config.seed.to_h if @config.seed
        @database.setup.seed(*sources)
        @database

      end

      private

      def self.load_config(config_file)

        raise RuntimeError, "Configuration file '#{config_file}' not found." unless File.exist?(config_file)

        config = Libis::Tools::ConfigFile.new({}, preserve_original_keys: false)
        config << config_file

        config

      end

    end

  end
end
