require 'libis-workflow-mongoid'

require_relative 'ingester/version'

module Libis
  module Ingester

    autoload :Config, 'libis/ingester/config'

    autoload :Flow, 'libis/ingester/flow'
    autoload :Run, 'libis/ingester/run'
    autoload :Task, 'libis/ingester/task'

    autoload :Item, 'libis/ingester/item'
    autoload :DirItem, 'libis/ingester/dir_item'
    autoload :FileItem, 'libis/ingester/file_item'

    autoload :Collection, 'libis/ingester/collection'
    autoload :IntellectualEntity, 'libis/ingester/intellectual_entity'
    autoload :Division, 'libis/ingester/division'
    autoload :Representation, 'libis/ingester/representation'

    autoload :IngestModel, 'libis/ingester/ingest_model'
    autoload :Manifestation, 'libis/ingester/manifestation'

    autoload :AccessRight, 'libis/ingester/access_right'
    autoload :RetentionPerion, 'libis/ingester/retention_period'
    autoload :RepresentationInfo, 'libis/ingester/representation_info'
    autoload :MetadataRecord, 'libis/ingester/metadata_record'

    def self.configure
      yield ::Libis::Ingester::Config.instance
    end

  end
end
