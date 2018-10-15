# frozen_string_literal: true
require 'libis/ingester'
require 'libis/tools/xml_document'
require 'libis/ingester/teneo/pip'

module Libis
  module Ingester

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

        process_pip(pip, run)

      end

      # @param [Libis::Ingester::Teneo::Pip] pip
      # @param [Libis::Ingster::Run] run
      def process_pip(pip, run)

        run.name = pip.id
        run.label = pip.label
        cfg = pip.config
        run.base_dir = cfg.base_dir || File.dirname(parameter(:pip_file))
        if cfg.ingest_model
          im = Libis::Ingester::IngestModel.find_by(name: cfg.ingest_model)
        end
        run.options['ingest_model'.freeze] = cfg.ingest_model if cfg.ingest_model
        pip.options.each do |opt|
          run.options[opt.key] = opt.content
        end
        pip.properties.each do |prop|
          run.properties[prop.key] = prop.content
        end
      end

    end

  end
end
