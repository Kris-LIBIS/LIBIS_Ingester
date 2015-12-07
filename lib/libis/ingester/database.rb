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

      def setup(cfg_dir = nil, config_file = nil)
        ::Libis::Ingester::User.create_indexes
        ::Libis::Ingester::Organization.create_indexes
        ::Libis::Ingester::AccessRight.create_indexes
        ::Libis::Ingester::RepresentationInfo.create_indexes
        ::Libis::Ingester::IngestModel.create_indexes
        ::Libis::Ingester::Workflow.create_indexes
        ::Libis::Ingester::Job.create_indexes
        ::Libis::Ingester::Run.create_indexes
        ::Libis::Ingester::Item.create_indexes
        Seed.new(
            cfg_dir || File.join(Libis::Ingester::ROOT_DIR, 'db', 'data'),
            config_file || File.join(Libis::Ingester::ROOT_DIR, '..', 'site.config.yml'),
        ).load_data
        self
      end

      def self.find_by_name(object, name)
        return nil unless name
        klass = object if object.is_a?(Class)
        klass ||= "::Libis::Ingester::#{object.to_s.classify}".constantize
        klass.find_by(name: name) ||
            warn("Could not find %s '%s'" % [klass.to_s.split('::').last.underscore.humanize.downcase, name])
      end

      class Seed

        attr_accessor :datadir, :config

        def initialize(dir, site_config = nil)
          @datadir = File.absolute_path(dir)
          @config = read_yaml(site_config) if site_config && File.exist?(site_config)
          @config.key_strings_to_symbols!(recursive: true)
        end

        # noinspection RubyResolve
        def load_data
          load_organization
          load_user(id_tag: [:user_id]) do |item, cfg|
            (cfg.delete('organizations') || []).each do |org_name|
              # noinspection RubyResolve
              item.organizations << find_object(:organization, org_name)
            end
          end
          load_access_right
          load_retention_period
          load_representation_info
          load_ingest_model do |item, cfg|
            item.access_right = find_object :access_right, cfg.delete('access_right')
            item.retention_period = find_object :retention_period, cfg.delete('retention_period')
            (cfg.delete('manifestations') || []).each do |mf_cfg|
              create_item(item.manifestations, mf_cfg, [:name]) do |mf, cfg_mf|
                mf.access_right = find_object :access_right, cfg_mf.delete('access_right')
                mf.representation_info = find_object :representation_info, cfg_mf.delete('representation')
                (cfg_mf.delete('convert') || []).each do |cv_cfg|
                  create_item(mf.convert_infos, cv_cfg, [:source_formats])
                end
              end
            end
          end
          load_workflow do |item, cfg|
            item.configure(cfg.to_hash.key_strings_to_symbols(recursive: true))
            cfg.clear
          end
          load_job do |item, cfg|
            item.workflow = find_object :workflow, cfg.delete('workflow')
            item.ingest_model = find_object :ingest_model, cfg.delete('ingest_model')
            item.organization = find_object :organization, cfg.delete('organization')
          end
        end

        private

        def find_object(object, name)
          ::Libis::Ingester::Database.find_by_name(object, name)
        end

        def method_missing(name, *args, &block)
          if name =~ /^load_(.*)$/
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
          cfg_list = Dir.entries(datadir).map do |filename|
            next unless filename =~ /_#{postfix}\.cfg$/
            read_yaml File.join(datadir, filename)
          end
          if @config && @config[:seed] && @config[:seed][postfix]
              cfg_list += @config[:seed][postfix] if @config[:seed][postfix].is_a?(Array)
          end
          cfg_list.compact.map do |cfg|
            block_given? ? yield(cfg) : cfg
          end
        end

        def create_item(klass, cfg, id_tag, &block)
          item = klass.find_or_initialize_by(cfg.select { |k, _| id_tag.include?(k.to_sym) })
          block.call(item, cfg) if block
          item.update_attributes(cfg)
          item.save!
        end

        def read_yaml(file)
          config = Libis::Tools::ConfigFile.new
          config << file
          config.to_h
        end

      end

    end
  end
end
