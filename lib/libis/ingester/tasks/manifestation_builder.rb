# encoding: utf-8
require 'libis-workflow'

require 'libis/ingester/file_item'
require 'libis/ingester/ingest_model'

module Libis
  module Ingester

    class ManifestationBuilder < Libis::Ingester::Task

      parameter ingest_model: nil,
                description: 'Ingest model name for the configuration of manifestations.'

      parameter recursive: true

      def process(item)

        return unless item.is_a? Libis::Ingester::FileItem

        mimetype = item.properties[:mimetype]
        raise WorkflowError, 'File item %s format not identified.' % item unless mimetype

        type_id = ::Libis::Format::TypeDatabase.mime_types(mimetype).first
        raise WorkflowError, 'File item %s format (%s) is not supported.' % [item, mimetype] unless type_id

        ingest_model_name = parameter(:ingest_model) || 'default'
        ingest_model ||= ::Libis::Ingester::IngestModel.find_by name: ingest_model_name
        raise WorkflowError, 'Ingest model %s not found.' % ingest_model_name unless ingest_model

        @manifestations = ingest_model.manifestations.where()


      end

    end

  end
end
