require 'libis-workflow-mongoid'

require_relative 'ingester/version'

module Libis
  module Ingester

    autoload :User, 'libis/ingester/user'
    autoload :Organization, 'libis/ingester/organization'
    autoload :Job, 'libis/ingester/job'

    autoload :Job, 'libis/ingester/job'
    autoload :Run, 'libis/ingester/run'

    autoload :Workflow, 'libis/ingester/workflow'
    autoload :Task, 'libis/ingester/task'

    autoload :IngestModel, 'libis/ingester/ingest_model'
    autoload :Manifestation, 'libis/ingester/manifestation'
    autoload :AccessRight, 'libis/ingester/access_right'
    autoload :RetentionPeriod, 'libis/ingester/retention_period'
    autoload :RepresentationInfo, 'libis/ingester/representation_info'
    autoload :ConvertInfo, 'libis/ingester/convert_info'

    autoload :Config, 'libis/ingester/config'
    autoload :Database, 'libis/ingester/database'
    autoload :DomainStorage, 'libis/ingester/domain_storage'

    autoload :Item, 'libis/ingester/item'
    autoload :DirItem, 'libis/ingester/dir_item'
    autoload :FileItem, 'libis/ingester/file_item'

    autoload :Collection, 'libis/ingester/collection'
    autoload :IntellectualEntity, 'libis/ingester/intellectual_entity'
    autoload :Division, 'libis/ingester/division'
    autoload :Representation, 'libis/ingester/representation'

    autoload :MetadataRecord, 'libis/ingester/metadata_record'

    def self.configure
      yield ::Libis::Ingester::Config.instance
    end

    ROOT_DIR = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))

  end
end

require_relative 'ingester/workers'
