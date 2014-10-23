require_relative 'ingester/version'

module LIBIS
  module Ingester

    autoload :Config, 'libis/ingester/config'

    autoload :Item, 'libis/ingester/item'
    autoload :Run, 'libis/ingester/run'
    autoload :Flow, 'libis/ingester/flow'

    autoload :DirItem, 'libis/ingester/dir_item'
    autoload :FileItem, 'libis/ingester/file_item'

    autoload :AccessRight, 'libis/ingester/access_right'
    autoload :Manifestation, 'libis/ingester/manifestation'
    autoload :MetadataRecord, 'libis/ingester/metadata_record'

    autoload :DavDossier, 'libis/ingester/dav_dossier'

    def self.configure
      yield ::LIBIS::Ingester::Config.instance
    end

  end
end
