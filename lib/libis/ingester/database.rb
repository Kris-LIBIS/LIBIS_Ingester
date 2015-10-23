require 'libis/ingester'

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
        Mongoid.purge!
        self
      end

      def setup(cfg_dir = nil)
        ::Libis::Ingester::Item.create_indexes
        ::Libis::Ingester::Organization.create_indexes
        ::Libis::Ingester::Account.create_indexes
        ::Libis::Ingester::IngestModel.create_indexes
        ::Libis::Ingester::AccessRight.create_indexes
        ::Libis::Ingester::Workflow.create_indexes
        ::Libis::Ingester::RepresentationInfo.create_indexes
        ::Libis::Ingester::Run.create_indexes
        Seed.new(cfg_dir || File.join(Libis::Ingester::ROOT_DIR, 'db', 'data')).
            organizations.
            accounts.
            access_right.
            representation_info.
            ingest_model.
            workflows
        self
      end

      def self.access_right(ar_name)
        if ar_name
          ar = Libis::Ingester::AccessRight.find_by(name: ar_name)
          return ar if ar
          warn 'Could not find access right \'%s\'', ar_name
        end
        Libis::Ingester::AccessRight.find_by(name: 'public')
      end

      def self.retention_period(rp_name)
        return nil unless rp_name
        rp = Libis::Ingester::RetentionPeriod.find_by(name: rp_name)
        return rp if rp
        warn 'Could not find retention_period \'%s\'', rp_name
        nil
      end

      def self.representation_info(rep_info_name)
        rep_info = Libis::Ingester::RepresentationInfo.find_by(name: rep_info_name)
        return rep_info if rep_info
        warn 'Could not find representation info \'%s\'', rep_info_name
        nil
      end

      def self.manifestation(mf_name, in_ingest_model)
        return nil unless mf_name
        mf = in_ingest_model.manifestations.find_by(name: mf_name)
        return mf if mf
        warn 'Could not find manifestation \'%s\' in ingest_model \'%s\'', mf_name, in_ingest_model.name
        nil
      end

      class Seed

        attr_accessor :datadir

        def initialize(dir)
          @datadir = File.absolute_path(dir)
        end

        def each_config(postfix)
          Dir.entries(datadir).map do |filename|
            next unless filename =~ /_#{postfix}\.cfg$/
            cfg_file = Libis::Tools::ConfigFile.new
            cfg_file << File.join(datadir, filename)
            cfg = cfg_file.to_h
            if block_given?
              yield cfg
            else
              cfg
            end
          end
          self
        end

        def load_config(postfix, klass, id_tag)
          each_config(postfix) do |cfg|
            item = klass.find_or_initialize_by(cfg.select { |k, _| id_tag.include?(k.to_sym) })
            yield item, cfg if block_given?
            item.update_attributes(cfg)
            item.save!
          end
        end

        def organizations
          load_config(:organization, ::Libis::Ingester::Organization, [:name])
        end

        def accounts
          load_config(:account, ::Libis::Ingester::Account, [:user_id])
        end

        def access_right
          load_config(:access_right, ::Libis::Ingester::AccessRight, [:name])
        end

        def representation_info
          load_config(:representation_info, ::Libis::Ingester::RepresentationInfo, [:name])
        end

        # noinspection RubyResolve
        def ingest_model
          load_config(:ingest_model, ::Libis::Ingester::IngestModel, [:name]) do |item, cfg|
            item.access_right = Libis::Ingester::Database.access_right(cfg.delete('access_right'))
            item.retention_period = Libis::Ingester::Database.retention_period(cfg.delete('retention_period'))
            (cfg.delete('manifestations') || []).each do |mf_cfg|
                mf = item.manifestations.find_or_initialize_by(name: mf_cfg[:name])
                mf.access_right = Libis::Ingester::Database.access_right(mf_cfg.delete('access_right'))
                mf.representation_info = Libis::Ingester::Database.representation_info(mf_cfg.delete('representation'))
                (mf_cfg.delete('convert') || []).each do |convert_cfg|
                  mf.convert_infos.find_or_initialize_by(convert_cfg)
                end
                mf.update_attributes(mf_cfg)
            end
          end
        end

        def workflows
          load_config(:workflow, ::Libis::Ingester::Workflow, [:name])
        end

      end

    end
  end
end
