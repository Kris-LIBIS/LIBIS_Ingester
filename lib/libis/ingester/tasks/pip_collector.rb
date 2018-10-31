# frozen_string_literal: true
require 'libis/ingester'
require 'libis/tools/xml_document'
require 'libis/ingester/teneo/pip'

module Libis
  module Ingester

    # noinspection RubyResolve
    class PipCollector < Libis::Ingester::Task

      taskgroup :collector
      description 'Collector for Teneo SIP files'

      help <<-STR.align_left
        This collector reads the Teneo SIP specification files and builds and configures the objects in the Ingester 
        database.
      STR

      parameter pip_file: nil,
                description: 'Teneo PIP file location'

      parameter item_types: [Libis::Ingester::Run], frozen: true

      protected

      XSD_FILE = ::Libis::Ingester::Config[:pip_xsd]

      # @param [Libis::Ingester::Run] run
      def process(run)
        @run = run
        xml_file = parameter(:pip_file)
        unless File.exist? xml_file
          raise Libis::WorkflowAbort,
                "PIP file '#{xml_file}' cannot be found."
        end

        xml = Libis::Tools::XmlDocument.open(xml_file)

        syntax_errors = xml.validate(XSD_FILE)
        if syntax_errors.any? {|e| e.level > 1}
          raise Libis::WorkflowAbort,
                "PIP file #{xml_file} is not valid according to the XSD Schema: #{syntax_errors.map {|e| "\n" + e.to_s}}"
        end

        if syntax_errors.any? {|e| e.level > 0}
          warn "PIP file #{xml_file} validation against XSD Schema returned warning(s): #{syntax_errors.map {|e| "\n" + e.to_s}}"
        end

        pip = Libis::Ingester::Teneo::Pip.from_xml(xml.document)

        parse_pip run, pip

      end

      # @param [Libis::Ingster::Run] run
      # @param [Libis::Ingester::Teneo::Pip] pip
      def parse_pip(run, pip)

        debug 'Parsing PIP document'

        parse_item run, pip

        cfg = pip.config

        run.base_dir = cfg.base_dir || File.dirname(parameter(:pip_file))

        if cfg.ingest_model
          im = Libis::Ingester::IngestModel.find_by(name: cfg.ingest_model)
          raise Libis::WorkflowAbort "Ingest model '#{cfg.ingest_model}' not found." unless im
          run.ingest_model = im
        end

        pip.collections.each do |collection|
          parse_collection run, collection
        end

        pip.ies.each do |ie|
          parse_ie run, ie
        end

        run.save!

      end

      # @param [Libis::Ingester::Item] parent
      # @param [Libis::Ingester::Teneo::Collection] pip_collection
      def parse_collection(parent, pip_collection)

        collection = Libis::Ingester::Collection.new
        parent << collection

        parse_item collection, pip_collection

        collection.navigate = pip_collection.navigate?
        collection.publish = pip_collection.publish?

        parse_metadata collection, pip_collection.metadata

        pip_collection.each do |col|
          parse_collection collection, col
        end

        pip_collection.ies.each do |ie|
          parse_ie collection, ie
        end

        collection.save!

      end

      # @param [Libis::Ingester::Item] parent
      # @param [Libis::Ingester::Teneo::Ie] pip_ie
      def parse_ie(parent, pip_ie)

        ie = Libis::Ingester::IntellectualEntity.new
        parent << ie

        parse_item(pip_ie, ie)

        ie.set_ingest_model(ie.ingest_model)

        ie.save!

      end

      # @param [Libis::Ingester::Item] item
      # @param [Libis::Ingester::Teneo::Ie] pip_item
      def parse_item(item, pip_item)

        item.name = pip_item.id
        item.label = pip_item.label

        pip_item.options.each do |opt|
          item.options[opt.key] = opt.content
        end

        pip_item.properties.each do |prop|
          item.properties[prop.key] = prop.content
        end

        item.save!

        debug "Defined #{item.class.name.split('::').last} #{collection.name} '#{collection.label}'", item.parent

      end

      # @param [Libis::Ingester::Item] item
      # @param [Libis::Ingester::Teneo::Metadata] pip_metadata
      def parse_metadata(item, pip_metadata)

        return unless pip_metadata

        if pip_metadata.record
          item.metadata = pip_metadata.record
        elsif pip_metadata.file
          file_info = pip_metadata.file
          metadata_file(item, file_info.path, file_info.format, file_info.format)
        elsif pip_metadata.search
          search_info = pip_metadata.search
          metadata_search(item, search_info.config, search_info.key)
        end

        item.save!

        debug 'Metadata added'

      end

      # @param [Libis::Ingester::Item] item
      # @param [String] path
      # @param [String] format
      # @param [String] mapping
      def metadata_file(item, path, format, mapping)

        return unless path

        path = join(@run.base_dir, path) unless File.exists?(path)
        return unless File.exists?(path)

        xml_doc = Libis::Tools::XmlDocument.new(path)

        data = case format

               when 'DC'
                 xml_doc.to_xml

               when 'MARC21'
                 record = Libis::Metadata::Marc21Record.new(xml_doc.root)
                 mapper_class = case mapping.lowercase
                                when 'kuleuven'
                                  Libis::Metadata::Mappers::KuLeuven
                                when 'kadoc'
                                  Libis::Metadata::Mappers::Scope
                                when 'flandrica'
                                  Libis::Metadata::Mappers::Flandrica
                                else
                                  nil
                                end
                 raise Libis::WorkflowAbort, "Unknown metadata mapper: '#{mapping}'." unless mapper_class
                 record.extend mapper_class
                 record.to_dc.to_xml

               else
                 raise Libis::WorkflowAbort, "Unknown metadata format: '#{format}'."

               end

        item.metadata_record.data = data
        item.metadata_record.format = 'DC'
      end

      # @param [String] config
      # @param [String] key
      # @param [Libis::Ingester::Item] item
      def metadata_search(item, config, key)
        return unless config && key


      end

    end

  end
end
