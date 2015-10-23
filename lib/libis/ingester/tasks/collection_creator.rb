# encoding: utf-8
require 'pathname'

require 'libis/ingester'

module Libis
  module Ingester

    class CollectionCreator < Libis::Ingester::Task

      parameter collection: nil,
                description: 'Existing collection to add the documents to.'

      parameter subitems: false
      parameter recursive: false

      def process(item)

        check_item_type ::Libis::Ingester::Run, item

        item.items.each { |i| create_collection(i) }

      end

      # noinspection RubyResolve
      def create_collection(item)

        return unless item.is_a? Libis::Ingester::Collection

        collection_list = item.ancestors.select do |i|
          i.is_a? Libis::Ingester::Collection
        end.map(&:name)
        collection_list << parameter(:collection) if parameter(:collection)

        @service = ::Libis::Services::Rosetta::Service.new
        @service.login('admin1', 'a1235678A', 'INS00') # TODO: remove hardcoded account

        parent_collection_id = create_collection_path(collection_list.reverse << item.name)
        collection_id = create_collection_item(parent_collection_id, collection_list.reverse, item.name, item.navigate, item.publish)

        debug "Created collection '#{item.name}' with id #{collection_id} in Rosetta.", item

      end

      def create_collection_path(list)
        return nil if list.empty?
        collection_name = list.pop
        begin
          parent_id = service.collection_service.find(list.reverse.join('/'))
          return
        rescue Libis::Services::SoapError => e
          unless e.detail == 'no_collection_found_exception'
            warn 'Collection lookup failed: %s', e.message
            return nil
          end
          parent_id = create_collection_path(list)
        end

        return nil unless parent_id or list.empty?

        create_collection_item(parent_id, list, collection_name, parameter(:navigate), parameter(:publish))
      end

      def create_collection_item(parent_id, collection_list, collection_name, navigate, publish)

        dc_record = Libis::Tools::Metadata::DublinCoreRecord.new
        dc_record.title = collection_name

        # noinspection RubyResolve
        dc_record.isPartOf = collection_list.reverse.join('/')

        collection_info = Libis::Services::Rosetta::CollectionHandler::CollectionInfo.new
        collection_info.name = collection_name
        collection_info.parent_id = parent_id
        collection_info.navigate = navigate
        collection_info.publish = publish
        collection_info.md_dc = Libis::Services::Rosetta::CollectionHandler::MetaData.new
        collection_info.md_dc.content = dc_record.to_s
        collection_info.md_dc.type = 'descriptive'
        collection_info.md_dc.sub_type = 'dc'

        @service.collection_service.create(collection_info)
      end

    end

  end
end
