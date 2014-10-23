# encoding: utf-8
require 'nori'
require 'libis/tools/assert'

module LIBIS
  module Ingester
    module Metadata

      class DublinCoreRecord

        def initialize(doc = nil)
          @doc = case doc
                   when ::LIBIS::Tools::XmlDocument
                     doc
                   when String
                     if File.exist?(doc)
                       # noinspection RubyResolve
                       LIBIS::Tools::XmlDocument.load(doc)
                     else
                       LIBIS::Tools::XmlDocument.parse(doc)
                     end
                   when IO
                     LIBIS::Tools::XmlDocument.parse(doc.read)
                   when Hash
                     LIBIS::Tools::XmlDocument.from_hash(doc)
                   when NilClass
                     LIBIS::Tools::XmlDocument.new.build do |xml|
                       xml.record('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                                  'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
                                  'xmlns:dcterms' => 'http://purl.org/dc/terms/') {
                         yield xml
                       }
                     end
                   else
                     raise ArgumentError, "Invalid argument: #{doc.inspect}"
                 end
        end

        def save(filename, options = {})
          @doc.save(filename, options)
        end

        def to_xml
          @doc.to_xml
        end

        def root
          @doc.document.root
        end

        def all
          @all_records ||= get_all_records
        end

        def value(key)
          get_node(key).content rescue nil
        end

        alias_method :[], :value

        def values(key)
          get_nodes(key).map &:content
        end

        def attribute(key, attr)
          get_node(key)[attr] rescue nil
        end

        def set_attribute(key, attr, value)
          node = get_node(key)
          raise RuntimeError, "Node #{node} not found." unless node
          node[attr] = value
        end

        def attributes(key, attr)
          get_nodes(key).map { |node| node[attr] }
        end

        def []=(key, value)
          get_node(key).content = value rescue add_node(key, value)
        end

        def << (*args)
          attributes = {}
          attributes = args.pop if args.last === Hash
          raise ArgumentError unless args.size == 2
          node = self[args.first] = args.second
          attributes.each {|k,v| node[k] = v}
        end

        protected

        def get_node(key)
          get_nodes(key).first
        end

        def get_nodes(key)
          key = key.to_s
          key = 'dc:' + key unless key =~ /^dc(terms)?:/
          root.xpath(key)
        end

        def add_node(key, value)
          root << @doc.create_text_node(key, value)
        end

      end

    end
  end
end
