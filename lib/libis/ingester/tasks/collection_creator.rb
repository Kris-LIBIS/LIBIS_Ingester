# encoding: utf-8
require 'pathname'

require 'libis/ingester'
require 'libis/services/rosetta'

module Libis
  module Ingester

    class CollectionCreator < Libis::Ingester::Task

      parameter collection: nil,
                description: 'Existing collection to add the documents to.'
      parameter navigate: true,
                description: 'Allow the user to navigate in the collections.'
      parameter publish: true,
                description: 'Publish the collections.'

      parameter subitems: true, frozen: true
      parameter recursive: true, frozen: true

      parameter item_types: [Libis::Ingester::Collection], frozen: true

      protected

      def process(item)
        create_collection(item)
        stop_processing_subitems unless item.items.no_timeout.any? { |i| i.is_a?(Libis::Ingester::Collection) }
      end

      private
      attr_accessor :rosetta

      # noinspection RubyResolve
      def create_collection(item, collection_list = nil)

        unless collection_list
          collection_list = item.ancestors.select do |i|
            i.is_a? Libis::Ingester::Collection
          end.map do |collection|
            collection.label
          end
          collection_list += parameter(:collection).split('/').reverse if parameter(:collection)
          collection_list = collection_list.reverse
        end

        unless @collection_service
          rosetta = Libis::Services::Rosetta::Service.new(
              Libis::Ingester::Config.base_url, Libis::Ingester::Config.pds_url,
              # log: Libis::Ingester::Config.logger, log_level: :debug
          )

          producer_info = item.get_run.producer
          handle = rosetta.login(producer_info[:agent], producer_info[:password], producer_info[:institution])
          raise Libis::WorkflowAbort, 'Could not log in into Rosetta.' if handle.nil?
          @collection_service = rosetta.collection_service
        end

        parent_id = item.parent.properties['collection_id'] if item.parent
        parent_id ||= create_collection_path(collection_list)

        collection_id = find_collection((collection_list + [item.label]).join('/'), item) ||
            create_collection_id(parent_id, collection_list, item.label, item.navigate, item.publish, item)

        item.properties['collection_id'] = collection_id

        debug "Created/found collection '#{item.label}' with id #{collection_id} in Rosetta.", item
      end

      def create_collection_path(list)
        list = list.dup
        return nil if list.blank?
        collection_id = find_collection(list.join('/'))
        return collection_id if collection_id

        collection_name = list.pop
        parent_id = create_collection_path(list)
        return nil unless parent_id or list.empty?

        begin
          create_collection_id(parent_id, list, collection_name, parameter(:navigate), parameter(:publish))
        rescue Exception => e
          raise Libis::WorkflowError, "Could not create collection '#{collection_name}': #{e.message}"
        end
      end

      def create_collection_id(parent_id, collection_list, collection_name, navigate, publish, item = nil)

        # noinspection RubyResolve
        if item && item.metadata_record
          dc_record = Libis::Tools::Metadata::DublinCoreRecord.new item.metadata_record.data
        else
          dc_record = Libis::Tools::Metadata::DublinCoreRecord.new
          dc_record.title = collection_name
        end

        # noinspection RubyResolve
        dc_record.isPartOf = collection_list.join('/') unless collection_list.empty?


        collection_data = {}
        collection_data[:name] = collection_name
        collection_data[:description] = 'Created by Ingester'
        collection_data[:parent_id] = parent_id if parent_id
        collection_data[:navigate] = navigate
        collection_data[:publish] = publish
        if item
          collection_data[:external_system] = item.external_system
          collection_data[:external_id] = item.external_id
        end
        collection_data[:md_dc] = {
            type: 'descriptive',
            sub_type: 'dc',
            content: dc_record.to_xml,
        }
        collection_info = Libis::Services::Rosetta::CollectionInfo.new collection_data.cleanup

        @collection_service.create(collection_info)
      end

      def find_collection(path, item = nil)
        return nil if path.blank?

        collection = @collection_service.find(path)
        return nil unless collection

        if item
          collection.description = item.description
          collection.navigate = item.navigate
          collection.publish = item.publish
          collection.external_system = item.external_system
          collection.external_id = item.external_id
          # noinspection RubyResolve
          if item.metadata_record
            dc_record = Libis::Tools::Metadata::DublinCoreRecord.new(item.metadata_record.data)
            collection.md_dc.type = 'descriptive'
            collection.md_dc.sub_type = 'dc'
            collection.md_dc.content = dc_record.to_xml
          end

          @collection_service.update(collection)
        end

        return collection.id

      rescue Libis::Services::SoapError => e
        unless e.message =~ /no_collection_found_exception/
          error 'Collection lookup failed: %s', e.message
        end
        nil
      end

    end

  end

end

