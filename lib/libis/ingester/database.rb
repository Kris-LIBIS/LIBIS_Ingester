require 'libis/ingester'
require 'libis/tools/extend/hash'

module Libis
  module Ingester
    class Database
      include ::Libis::Workflow::Base::Logger

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
        ::Libis::Ingester::PersistentStorage.create_indexes
        ::Libis::Ingester::RepresentationInfo.create_indexes
        ::Libis::Ingester::RetentionPeriod.create_indexes
        ::Libis::Ingester::Run.create_indexes
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
                @config.merge!(source.key_strings_to_symbols(recursive: true))
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
          load_user do |item, cfg|
            item.organizations.clear
            (cfg.delete(:organizations) || []).each do |org_name|
              add_item(item.organizations, {name: org_name}, [:name])
            end
          end
          load_access_right
          load_retention_period
          load_representation_info
          load_ingest_model do |item, cfg|
            item.access_right = find_or_create_object :access_right, cfg.delete(:access_right)
            item.retention_period = find_or_create_object :retention_period, cfg.delete(:retention_period)
            item.manifestations.clear
            (cfg.delete(:manifestations) || []).each do |mf_cfg|
              add_item(item.manifestations, mf_cfg, [:name]) do |mf, cfg_mf|
                mf.access_right = find_or_create_object :access_right, cfg_mf.delete(:access_right)
                mf.representation_info = find_or_create_object :representation_info, cfg_mf.delete(:representation)
                mf.convert_infos.clear
                (cfg_mf.delete(:convert) || []).each do |cv_cfg|
                  add_item(mf.convert_infos, cv_cfg, [:source_formats])
                end
              end
            end
          end
          load_workflow do |item, cfg|
            item.configure(cfg.to_hash.key_strings_to_symbols(recursive: true))
            cfg.clear
          end
          load_job do |item, cfg|
            item.workflow = find_or_create_object :workflow, cfg.delete(:workflow)
            item.ingest_model = find_or_create_object :ingest_model, cfg.delete(:ingest_model)
            item.organization = find_or_create_object :organization, cfg.delete(:organization)
          end
        end

        private

        def method_missing(name, *args, &block)
          if name =~ /^load_(.*)$/
            puts "Loading #{$1}s ..."
            options = {
                postfix: $1.to_sym,
                klass: "Libis::Ingester::#{$1.classify}".constantize,
                id_tag: [:name]
            }
            options.merge!(args[0]) if args[0] && args[0].is_a?(Hash)
            load_config options, &block
          else
            super
          end
        end

        def load_config(options = {}, &block)
          each_config(options[:postfix]) do |cfg|
            create_item(options[:klass], cfg, options[:id_tag], &block)
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

        def add_item(klass, cfg, id_tag, &block)
          create_item(klass, cfg, id_tag, true, &block)
        end

        def create_item(klass, cfg, id_tag, adding = false, &block)
          @indent ||= -1
          @indent += 1
          indent_txt = '  ' * @indent
          item = klass.find_or_initialize_by(cfg.select { |k, _| id_tag.include?(k.to_sym) })
          item_txt = "#{item.class} #{item.respond_to?(:name) ? "'#{item.name}'" : ''}"
          is_new = item.new_record?
          if is_new
            action_txt = adding ? 'Adding' : 'Creating'
            puts "  #{indent_txt}#{action_txt} #{item_txt}.#{' !!! CHECK !!!' if @indent > 0 && !adding}"
          else
            action_txt = (@indent == 0 || adding) ? 'Found' : 'Linking'
            puts "  #{indent_txt}#{action_txt} #{item_txt}."
          end
          block.call(item, cfg) if block
          item.update_attributes(cfg)
          puts "  #{indent_txt}Updated #{item_txt}." if item.changed? unless is_new
          item.save!
          @indent -= 1
          item
        end

        def find_or_create_object(object, name)
          return nil if name.nil?
          klass = object if object.is_a?(Class)
          klass ||= "::Libis::Ingester::#{object.to_s.classify}".constantize
          create_item(klass, {name: name}, [:name])
        end

        def read_yaml(file)
          config = Libis::Tools::ConfigFile.new({}, preserve_original_keys: false)
          config << file
          config.to_h
        end

      end

    end
  end
end
