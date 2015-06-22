require 'libis/ingester'

module Libis
  module Ingester
    class Database

      def initialize
        ::Libis::Ingester.configure do |cfg|
          # noinspection RubyResolve
          cfg.database_connect 'mongoid.yml', :test
        end
        Mongoid.purge!
      end

      def setup
        ::Libis::Ingester::Item.create_indexes
        ::Libis::Ingester::IngestModel.create_indexes
        ::Libis::Ingester::AccessRight.create_indexes
        ::Libis::Ingester::Flow.create_indexes
        ::Libis::Ingester::RepresentationInfo.create_indexes
        ::Libis::Ingester::Run.create_indexes
        Seed.access_right
        Seed.representation_info
        Seed.ingest_model
      end

      class Seed

        def self.access_right
          ::Libis::Ingester::AccessRight.create(
              name: 'public',
              ar_id: 'AR_EVERYONE'
          )
        end

        def self.ingest_model
          ::Libis::Ingester::IngestModel.create(
              name: 'default',
              description: 'Just uploads the files as-is without any preprocessing',
              producer: 'admin1',
              material_flow: '5', # 'METS deposit'
          ).manifestations.new(
              name: 'ARCHIVE',
              access_right: Libis::Ingester::AccessRight.find_by(name: 'public')
          ).save
        end

        def self.representation_info
          ::Libis::Ingester::RepresentationInfo.create(
              name: 'ARCHIVE',
              label: 'Archiefkopie',
              preservation_type: 'PRESERVATION_MASTER',
              usage_type: 'VIEW'
          )
          ::Libis::Ingester::RepresentationInfo.create(
              name: 'VIEW_MAIN',
              label: 'Lage kwaliteit',
              preservation_type: 'DERIVATIVE_COPY',
              usage_type: 'VIEW',
              representation_code: 'LOW'
          )
          ::Libis::Ingester::RepresentationInfo.create(
              name: 'VIEW',
              label: 'Hoge kwaliteit',
              preservation_type: 'DERIVATIVE_COPY',
              usage_type: 'VIEW',
              representation_code: 'HIGH'
          )
        end

      end

    end
  end
end

::Libis::Ingester::Database.new.setup
