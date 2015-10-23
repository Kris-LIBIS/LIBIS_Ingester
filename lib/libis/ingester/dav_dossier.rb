# encoding: utf-8

require 'libis/workflow'

require_relative 'intellectual_entity'

module Libis
  module Ingester

    class DavDossier < Libis::Ingester::IntellectualEntity
      include Libis::Workflow::Base::DirItem

      def filepath
        ''
      end

    end

  end
end
