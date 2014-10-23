# encoding: utf-8

require 'LIBIS_Workflow'

require_relative 'item'
module LIBIS
  module Ingester

    class DavDossier < LIBIS::Ingester::Item
      include ::LIBIS::Workflow::DirItem

      field :ingest_type, type: String, default: 'METS'

      def filepath
        ''
      end

    end

  end
end
