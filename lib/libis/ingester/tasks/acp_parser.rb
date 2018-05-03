# frozen_string_literal: true

require 'libis/ingester'
require_relative 'base/xml_parser'

require 'fileutils'

require 'awesome_print'

NAME_ELEMENT = /^abs:isad(Archief|Domein|Subdomein|Rubriek|Reeks|Serie|Groep|Dossier)$/
IE_ELEMENT = /^(abs:isadStuk|cm:content)$/
CONTAINER_ELEMENT = /^(view:view|cm:contains|cm:thumbnails)$/
THUMBNAIL_ELEMENT = 'cm:thumbnail'
BACKLOG_ELEMENT = 'cm:content'
STUK_ELEMENT = 'abs:isadStuk'

module Libis
  module Ingester

    class AcpParser < Libis::Ingester::Task
      attr_accessor :element_stack, :element_path

      taskgroup :collector
      description 'Parses an extracted ACP file and collects IE from that'

      help <<-STR.align_left
        This collector needs an extracted ACP file. The given XML file - normally the file in the root of the exported
        ACP file - will be parsed and for each <abs:isadStuk> entry an IE will be created.
      STR

      parameter acp_dir: nil,
                description: 'The folder where the ACP (Alfresco Content Package) export file was extracted.'

      parameter item_types: [Libis::Ingester::Run], frozen: true

      protected

      # @param [Libis::Ingester::Run] item
      def process(item)
        unless Dir.exist?(parameter(:acp_dir))
          raise Libis::WorkflowAbort, "ACP directory '#{parameter(:acp_dir)}' cannot not be found."
        end

        xml_files = Dir.glob(File.join(parameter(:acp_dir), '*.xml'))
        unless xml_files.count == 1
          raise Libis::WorkflowAbort, "ACP directory should contain only 1 XML file."
        end

        xml_file = xml_files.first
        parse_xml(xml_file, item)

      end

      def parse_xml(xml_file, item)
        element_stack = [] # stack of all elements traversed
        element_path = [] # stack of relevant elements traversed
        name_path = [] # stack of names
        ie = nil
        Libis::Ingester::Base::XmlParser.new(xml_file) do |function, *args|
          # puts "Called: #{function}"
          # ap args
          case function
          when :start_element
            element = args[0]
            element_stack.push(element)
            if element_stack[-2] =~ CONTAINER_ELEMENT
              element_path.push(element)
              attrs = args[1].reduce({}) {|r, x| r[x[0]] = x[1]; r}
              child_name = attrs['view:childName']&.gsub(/^cm:/, '')
              case element
              when NAME_ELEMENT
                name_path.push(child_name)
              when IE_ELEMENT
                ie = {}
                ie[:name] = child_name if child_name
                ie[:path] = name_path.join('/')
              else # nothing
              end
            end
          when :end_element
            element = args[0]
            raise WorkflowAbort, "Error processing XML: unexpected closing tag" unless element == element_stack.pop
            if element_stack[-1] =~ CONTAINER_ELEMENT
              case element
              when NAME_ELEMENT
                name_path.pop
              when IE_ELEMENT
                create_ie ie, item if ie
                ie = nil
              else # nothing
              end
            end
          when :characters
            string = args[0].strip
            unless string.empty?
              if ie
                case element_path[-1]
                when IE_ELEMENT
                  case element_stack[-1]
                  when 'abs:isadMedium'
                    if 'Digitaal' != string
                      ie = nil
                    end
                  when 'abs:isadOrigineel'
                    ie[:original] = parse_content_string(string)
                  when 'cm:content'
                    case element_path[-1]
                    when STUK_ELEMENT
                      ie[:derived] = parse_content_string(string)
                    when BACKLOG_ELEMENT
                      ie[:original] = parse_content_string(string)
                    else # nothing
                    end
                  when 'cm:name'
                    ie[:name] = string
                  when 'abs:isadRaadpleegformaatNaam'
                    ie[:deriv_name] = string
                  when 'sys:node-dbid'
                    ie[:vp_dbid] = string
                  when 'sys:node-uuid'
                    ie[:vp_uuid] = string
                  when 'abs:isadAanmaakDatum'
                    ie[:created] = DateTime.parse(string)
                  when 'cm:created'
                    ie[:created] ||= DateTime.parse(string)
                  when 'abs:isadTitel'
                    ie[:label] = string
                  when 'od:titel'
                    ie[:label] = string + ' - ' + name_path[-1]
                  when 'abs:checksum'
                    ie[:checksum] = string
                  else # nothing
                  end
                when THUMBNAIL_ELEMENT
                  case element_stack[-1]
                  when 'cm:content'
                    ie[:thumbnail] = parse_content_string(string)
                  else # nothing
                  end
                else # nothing
                end
              else # ie
                case element_stack[-1]
                when 'view:exportOf'
                  name_path = string.gsub('/cm:', '/').gsub(/_x[^_]*_/) do |x|
                    ["0#{x.tr('_', '')}".to_i(16)].pack('U')
                  end.split('/')[4..-1]
                when 'abs:isadTitel'
                  if element_path[-1] =~ NAME_ELEMENT
                    name_path.pop
                    name_path.push(string)
                  end
                else # nothing
                end
              end
            end
          else # nothinh
          end # function

        end
      end

      private

      def parse_content_string(string)
        result = {}
        if string =~ /contentUrl=([^|]*)/
          result[:file] = $1
        end
        if string =~ /mimetype=([^|]*)/
          result[:mime] = $1
        end
        if string =~ /size=([^|]*)/
          result[:size] = $1.to_i
        end
        result
      end

      def create_file(source, size, target, date, checksum = nil)

        return nil unless source

        file_name = File.join(parameter(:acp_dir), source)
        unless File.exist?(file_name)
          error "Could not find file '#{source}' in the ACP directory"
          return nil
        end

        File.utime(date.to_time, date.to_time, file_name)
        file_item = Libis::Ingester::FileItem.new
        file_item.filename = file_name

        unless file_item.properties['size'] == size
          error "File #{source} size does not match metadata info [#{file_item.properties['size']} vs #{size}]"
          return nil
        end

        unless file_item.properties['checksum_md5'] == checksum
          error "File #{source} checksum does not match metadata info [#{file_item.properties['checksum_md5']} vs #{checksum}]"
          return nil
        end if checksum

        file_item.properties['access_time'] = date
        file_item.properties['modification_time'] = date
        file_item.properties['creation_time'] = date
        file_item.properties['original_path'] = target
        file_item[:label] = File.basename(target)

        file_item.save!
        file_item

      end

      def create_ie(data, parent)

        raise WorkflowError, "Missing original file information for IE '#{ie_info(data)}'" if data[:original]&.empty?

        # create IE
        ie = Libis::Ingester::IntellectualEntity.new
        ie.name = data[:name]
        ie.label = data[:label] || data[:name]
        ie.parent = parent
        ie.properties['vp_dbid'] = data[:vp_dbid]
        record = MetadataRecord.new
        record.format = 'DC'
        record.data = Libis::Tools::Metadata::DublinCoreRecord.build do |dc|
          dc.title = data[ie.label]
          dc.identifier = "dbid:#{data[:vp_dbid]}"
          dc.identifier = "uuid:#{data[:vp_uuid]}"
          # noinspection RubyResolve
          dc.isPartOf = data[:path] if data[:path]
        end.to_xml
        ie.metadata_record = record
        debug "Created IE for '#{ie_info(data)}'"
        ie.save!

        date = DateTime.iso8601(data[:created])

        if (original = create_file(data[:original][:file], data[:original][:size], data[:name], date, data[:checksum]))
          original.properties['rep_type'] = 'original'
          original.save!
          ie << original
          ie.save!
          debug "Added original file to IE", ie
        else
          raise WorkflowError, "Failed to create original FileItem for IE '#{ie_info(data)}'"
        end

        if (derived = create_file(data[:derived][:file], data[:derived][:size], (data[:deriv_name] || data[:name]), date))
          derived.properties['rep_type'] = 'derived'
          derived.save!
          ie << derived
          ie.save!
          debug "Added derived file to IE", ie
        end if data[:derived] && data[:derived] != data[:original]

        if data[:thumbnail]&.any?
          fname = "#{File.basename data[:name]}#{File.extname data[:thumbnail][:file]}"
          if (thumbnail = create_file(data[:thumbnail][:file], data[:thumbnail][:size], fname, date))
            thumbnail.properties['rep_type'] = 'thumbnail'
            thumbnail.save!
            ie << thumbnail
            ie.save!
            debug "Added thumbnail file to IE", ie
          end
        end
      end

      def ie_info(ie)
        [
            ie[:name],
            ie[:vp_dbid]&.to_s || ie[:vp_uuid]
        ].join(' ')
      end

    end

  end
end
