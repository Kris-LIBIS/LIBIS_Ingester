require 'libis/ingester'
require 'libis/tools/extend/hash'

module Libis
  module Ingester
    class Database
      include ::Libis::Tools::Logger

      def initialize(cfg_file = nil, env = :production)
        ::Libis::Ingester.configure do |cfg|
          # noinspection RubyResolve
          cfg.database_connect((cfg_file || 'mongoid.yml'), env)
        end
      end

      def clear
        ::Libis::Ingester::Run.destroy_all rescue nil
        Mongoid.purge!
        self
      end

      def setup
        ::Libis::Ingester::AccessRight.create_indexes
        ::Libis::Ingester::IngestModel.create_indexes
        ::Libis::Ingester::Item.create_indexes
        ::Libis::Ingester::Job.create_indexes
        ::Libis::Ingester::Organization.create_indexes
        ::Libis::Ingester::DomainStorage.create_indexes
        ::Libis::Ingester::RepresentationInfo.create_indexes
        ::Libis::Ingester::RetentionPeriod.create_indexes
        ::Libis::Ingester::User.create_indexes
        ::Libis::Ingester::Workflow.create_indexes
        self
      end

      def seed(*args)
        sources = [File.join(Libis::Ingester::ROOT_DIR, 'db', 'data')] + args
        Seed.new(sources).load_data
        self
      end

      def self.find_by_name(object, name)
        return nil unless name
        klass = object if object.is_a?(Class)
        klass ||= "::Libis::Ingester::#{object.to_s.classify}".constantize
        klass.find_by(name: name) ||
            warn("Could not find %s '%s'" % [klass.to_s.split('::').last.underscore.humanize.downcase, name])
      end

      def self.find_or_create_by_name(object, name)
        return nil unless name
        klass = object if object.is_a?(Class)
        klass ||= "::Libis::Ingester::#{object.to_s.classify}".constantize
        klass.find_or_create_by(name: name)
      end

      class Seed

        attr_accessor :datadir, :config

        def initialize(sources)
          @datadir = []
          @config = {}
          sources.each do |source|
            case source
              when Hash
                @config.merge!(source.key_symbols_to_strings(recursive: true))
              when String
                raise RuntimeError, "'#{source}' not found." unless File.exist?(source)
                if File.directory?(source)
                  @datadir << source
                elsif File.file?(source)
                  cfg = read_yaml(source)
                  cfg = cfg.seed if cfg.seed
                  @config.merge(cfg)
                end
              else
                raise RuntimeError, 'Should supply a hash or file/directory name.'
            end
          end
        end

        # noinspection RubyResolve
        def load_data
          load_organization
          load_user
          load_access_right
          load_retention_period
          load_representation_info
          load_ingest_model
          load_workflow
          load_job
        end

        private

        def method_missing(name, *args, &block)
          if name =~ /^load_(.*)$/
            puts "Loading #{$1}s ..."
            options = {
                postfix: $1.to_s,
                klass: "Libis::Ingester::#{$1.classify}".constantize
            }
            options.merge!(args[0]) if args[0] && args[0].is_a?(Hash)
            load_config options, &block
          else
            super
          end
        end

        def load_config(options = {})
          each_config(options[:postfix]) do |cfg|
            puts cfg
            yield(cfg) if block_given?
            options[:klass].from_hash(cfg)
          end
        end

        def each_config(postfix)
          cfg_list = []
          @datadir.each do |dir|
            Dir.entries(dir).each do |filename|
              next unless filename =~ /_#{postfix}\.cfg$/
              cfg_list << read_yaml(File.join(dir, filename))
            end
          end
          case @config[postfix]
            when Array
              cfg_list += @config[postfix]
            when Hash
              cfg_list << @config[postfix]
            else
              #skip
          end
          cfg_list.compact.map do |cfg|
            block_given? ? yield(cfg) : cfg
          end
        end

        def read_yaml(file)
          puts "\t ... #{File.basename file}"
          config = Libis::Tools::ConfigFile.new({}, preserve_original_keys: false)
          config << file
          config.to_h.key_symbols_to_strings(recursive: true)
        end

      end

    end
  end
end
