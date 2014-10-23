# coding: utf-8

require 'set'
require 'cgi'

require 'libis/tools/xml_document'
require 'libis/tools/assert'

require_relative 'fix_field'
require_relative 'var_field'
require_relative 'field_spec'

module LIBIS
  module Ingester
    module Metadata

# noinspection RubyTooManyMethodsInspection
      class MarcRecord

        def initialize(xml_node)
          @node = xml_node
        end

        def to_raw
          @node
        end

        def all
          @all_records ||= get_all_records
        end

        def each
          all.each do |k, v|
            yield k, v
          end
        end

        def all_tags(tag, subfields = '')
          tag_, ind1, ind2 = tag =~ /^\d{3}/ ? [tag[0..2], tag[3], tag[4]] : [tag, nil, nil]
          result = get_records(tag_, ind1, ind2, subfields)
          return result unless block_given?
          result.map { |record| yield record }
          result.size > 0
        end

        def first_tag(t, subfields = '')
          result = all_tags(t, subfields).first
          return result unless block_given?
          return false unless result
          yield result
          true
        end

        def each_tag(t, s = '')
          all_tags(t, s).each do |record|
            yield record
          end
        end

        def all_fields(t, s)
          r = all_tags(t, s).collect { |tag| tag.fields_array(s) }.flatten.compact
          return r unless block_given?
          r.map { |field| yield field }
          r.size > 0
        end

        def first_field(t, s)
          result = all_fields(t, s).first
          return result unless block_given?
          return false unless result
          yield result
          true
        end


        def each_field(t, s)
          all_fields(t, s).each do |field|
            yield field
          end
        end

        def marc_dump
          all.values.flatten.each_with_object([]) { |record, m| m << record.dump }.join
        end

        def save(filename)

          doc = ::LIBIS::Tools::XmlDocument.new
          doc.root = @node

          return doc unless filename

          doc.save filename, save_with: ( ::Nokogiri::XML::Node::SaveOptions::NO_EMPTY_TAGS |
              ::Nokogiri::XML::Node::SaveOptions::AS_XML |
              ::Nokogiri::XML::Node::SaveOptions::FORMAT
          )

        end

        def self.load(filename)

          doc = ::LIBIS::Tools::XmlDocument.open(filename)
          self.new(doc.root)

        end

        def self.read(io)
          io = StringIO.new(io) if io.is_a? String
          doc = ::LIBIS::Tools::XmlDocument.parse(io)
          self.new(doc.root)

        end

        def to_aseq
          record = ''
          doc_number = tag('001').datas

          all.select { |t| t.is_a? FixField }.each { |t| record += "#{format('%09s', doc_number)} #{t.tag}   L #{t.datas}\n" }
          all.select { |t| t.is_a? VarField }.each { |t|
            record += "#{format('%09s', doc_number)} #{t.tag}#{t.ind1}#{t.ind2} L "
            t.keys.each { |k|
              t.field_array(k).each { |f|
                record += "$$#{k}#{CGI::unescapeHTML(f)}"
              }
            }
            record += "\n"
          }

          record
        end

        protected

        def element(*parts)
          opts = options parts
          field_spec(opts, *parts)
        end

        def list_s(*parts)
          opts = options parts, join: ' '
          field_spec(opts, *parts)
        end

        def list_c(*parts)
          opts = options parts, join: ', '
          field_spec(opts, *parts)
        end

        def list_d(*parts)
          opts = options parts, join: ' - '
          field_spec(opts, *parts)
        end

        def repeat(*parts)
          opts = options parts, join: '; '
          field_spec(opts, *parts)
        end

        def opt_r(*parts)
          opts = options parts, fix: '()'
          field_spec(opts, *parts)
        end

        def opt_s(*parts)
          opts = options parts, fix: '[]'
          field_spec(opts, *parts)
        end

        def odis_link(group, id, label)
          "http://www.odis.be/lnk/#{group.downcase[0, 2]}_#{id}\##{label}"
        end

        private

        def options(args, default = {})
          default.merge(args.last.is_a?(::Hash) ? args.pop : {})
        end

        def field_spec(default_options, *parts)
          FieldSpec.new(*parts).add_default_options(default_options).to_s
        end

        def get_records(tag, ind1 = '', ind2 = '', subfields = '')

          ind1 ||= ''
          ind2 ||= ''
          subfields ||= ''

          ind1.tr!('_', ' ')
          ind1.tr!('#', '')

          ind2.tr!('_', ' ')
          ind2.tr!('#', '')

          all[tag].select do |v|
            v.is_a?(FixField) ||
                ((ind1.empty? or v.ind1 == ind1) &&
                    (ind2.empty? or v.ind2 == ind2) &&
                    v.match_fieldspec?(subfields)
                )
          end

        end

      end
    end
  end
end
