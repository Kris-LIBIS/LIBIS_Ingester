# encoding: utf-8

require 'libis/ingester'

module Libis
  module Ingester

    class MetadataCollector < Libis::Ingester::Task

      parameter item_types: %w'Libis::Ingester::IntellectualEntity Libis::Ingester::Collection',
                description: 'Items types to process for metadata.'
      parameter recursive: true, frozen: true

      parameter converter: '',
                description: 'Dublin Core metadata converter to use.',
                constraint: ['', 'Kuleuven', 'Flandrica', 'Scope']

      parameter title_to_name: false,
                description: 'Update the item name with the title in the metadata?'

      parameter title_to_label: true,
                description: 'Update the item label with the title in the metadata?'

      parameter new_name: nil,
                description: 'Ruby expression that transforms the name.'

      parameter new_label: nil,
                description: 'Ruby expression that transforms the label.'

      parameter fail_on_missing: false,
                description: 'Raise an error if a metadata record is missing?'

      protected

      def process(item)
        record = get_record(item)
        unless record
          raise Libis::WorkflowError, 'No metadata record.' if parameter(:fail_on_missing)
          return
        end
        record = convert_metadata(record)
        assign_metadata(item, record)
      rescue Libis::WorkflowError
        raise
      rescue Exception => e
        error 'Error getting metadata: %s', e.message
        debug 'At: %s', e.backtrace.first
        set_status(item, :FAILED)
        raise Libis::WorkflowError, 'MetadataCollector failed.'
      end

      def get_record(item)
        nil
      end

      private

      def assign_metadata(item, record)
        metadata_record = Libis::Ingester::MetadataRecord.new
        metadata_record.format = 'DC'
        metadata_record.data = record.to_xml
        # noinspection RubyResolve
        item.metadata_record = metadata_record
        info 'Metadata added to \'%s\'', item, item.name
        transform_item(item, record.title.content)
        item.save!
      end

      def transform_item(item, title)
        item.name = title if parameter(:title_to_name)
        item.name = eval(parameter(:new_name)) if parameter(:new_name)
        item.label = title if parameter(:title_to_label)
        item.label = eval(parameter(:new_label)) if parameter(:new_label)
      end

      def convert_metadata(record)
        return record if parameter(:converter).blank?
        mapper_class = "Libis::Tools::Metadata::Mappers::#{parameter(:converter)}".constantize
        unless mapper_class
          raise Libis::WorkflowAbort, "Metadata converter class `#{parameter(:converter)}` not found."
        end
        record.extend mapper_class
        record.to_dc
      end

    end

  end
end
