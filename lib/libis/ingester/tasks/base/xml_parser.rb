require 'nokogiri'

module Libis
  module Ingester
    module Base
      class XmlParser < Nokogiri::XML::SAX::Document
        attr_reader :callback

        def initialize(document, callback = nil, &block)
          @callback = callback || block
          raise WorkflowAbort, "XmlParser created without callback or block" unless @callback
          File.open(document) do |f|
            Nokogiri::XML::SAX::Parser.new(self).parse(f)
          end
        end

        def xmldecl(version, encoding, standalone)
          callback.call :xmldecl, version, encoding, standalone
        end

        def start_document
          callback.call :start_document
        end

        def comment(string)
          callback.call :comment, string
        end

        def processing_instruction(name, content)
          callback.call :processing_instruction, name, content
        end

        def start_element(name, attrs = [])
          callback.call :start_element, name, attrs
        end

        def start_element_namespace(name, attrs = [], prefix = nil, uri = nil, ns = nil)
          super
          callback.call :start_element_namespace, name, attrs, prefix, uri, ns
        end

        def cdata_block(string)
          callback.call :cdata_block, string
        end

        def characters(string)
          callback.call :characters, string
        end

        def end_element(name)
          callback.call :end_element, name
        end

        def end_element_namespace(name, prefix = nil, uri = nil)
          super
          callback.call :end_element_namespace, name, prefix, uri
        end

        def end_document
          callback.call :end_document
        end

        def error(string)
          callback.call :error, string
        end

        def warning(string)
          callback.call :warning, string
        end

      end
    end
  end
end
