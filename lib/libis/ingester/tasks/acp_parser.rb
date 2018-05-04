# frozen_string_literal: true
require 'libis/ingester'
require_relative 'base/xml_parser'

PATH_ELEMENT = /^isad(Archief|Domein|Subdomein|Rubriek|Reeks|Serie|Groep|Dossier|Stuk|content|thumbnail)$/
NAME_ELEMENT = /^isad(Archief|Domein|Subdomein|Rubriek|Reeks|Serie|Groep|Dossier)$/
CONTAINER_ELEMENT = /^(view|contains|thumbnails)$/
THUMBNAIL_ELEMENT = 'thumbnail'
BACKLOG_ELEMENT = 'content'
STUK_ELEMENT = 'isadStuk'
IE_ELEMENT = /^(#{STUK_ELEMENT}|#{BACKLOG_ELEMENT})$/

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
        name_path = [] # stack of relevant names
        ie = nil
        Libis::Ingester::Base::XmlParser.new(xml_file) do |function, *args|
          case function
          when :start_element_namespace
            element = args[0]
            element_stack.push(element)
            if element_stack[-2] =~ CONTAINER_ELEMENT
              element_path.push(element) if element =~ PATH_ELEMENT
              attrs = args[1].reduce({}) {|r, x| r[x[0]] = x[3]; r}
              child_name = attrs['childName']&.gsub(/^cm:/, '')
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
          when :end_element_namespace
            element = args[0]
            raise WorkflowAbort, "Error processing XML: unexpected closing tag" unless element == element_stack.pop
            if element_stack[-1] =~ CONTAINER_ELEMENT
              element_path.pop if element =~ PATH_ELEMENT
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
            string = args[0]
            if ie
              case element_path[-1]
              when IE_ELEMENT
                case element_stack[-1]
                when 'isadMedium'
                  if 'Digitaal' != string
                    ie = nil
                  end
                when 'isadOrigineel'
                  ie[:original] = parse_content_string(string)
                when 'content'
                  case element_path[-1]
                  when STUK_ELEMENT
                    ie[:derived] = parse_content_string(string)
                  when BACKLOG_ELEMENT
                    ie[:original] = parse_content_string(string)
                  else # nothing
                  end
                when 'isadRaadpleegformaatNaam'
                  ie[:deriv_name] = string
                when 'node-dbid'
                  ie[:vp_dbid] = string
                when 'node-uuid'
                  ie[:vp_uuid] = string
                when 'isadAanmaakDatum'
                  ie[:created] = DateTime.parse(string)
                when 'created'
                  ie[:created] ||= DateTime.parse(string)
                when 'isadTitel'
                  ie[:label] = string
                when 'titel'
                  ie[:label] = name_path[-1] + ' - ' + string
                when 'checksum'
                  ie[:checksum] = string
                when 'isadReferentie'
                  ie[:refcode] = string
                else # nothing
                end
              when THUMBNAIL_ELEMENT
                case element_stack[-1]
                when 'content'
                  ie[:thumbnail] = parse_content_string(string)
                else # nothing
                end
              else # nothing
              end
            else # ie
              case element_stack[-1]
              when 'exportOf'
                name_path = string.gsub('/cm:', '/').gsub(/_x[^_]*_/) do |x|
                  ["0#{x.tr('_', '')}".to_i(16)].pack('U')
                end.split('/')[4..-1]
              when 'isadTitel'
                if element_path[-1] =~ NAME_ELEMENT
                  name_path.pop
                  name_path.push(string)
                end
              else # nothing
              end
            end # if ie
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
        unless data[:original][:size] > 0
          error "Original contains file with size 0. File '#{data[:original][:file]}' will be skipped and no IE will be created."
        end

        # create IE
        ie = Libis::Ingester::IntellectualEntity.new
        ie.name = data[:name]
        ie.label = data[:label] || (data[:path].split('/')[-1] + ' - ' + data[:name])
        ie.parent = parent
        ie.properties['path'] = data[:path] if data[:path]
        ie.properties['vp_dbid'] = data[:vp_dbid] if data[:vp_dbid]
        ie.properties['vp_uuid'] = data[:vp_uuid] if data[:vp_uuid]
        ie.properties['refcode'] = data[:refcode] if data[:refcode]
        record = MetadataRecord.new
        record.format = 'DC'
        dc = Libis::Tools::Metadata::DublinCoreRecord.new
        dc.title = data[ie.label]
        # noinspection RubyResolve
        dc.identifier! "refcode:#{data[:refcode]}" if data[:refcode]
        # noinspection RubyResolve
        dc.identifier! "dbid:#{data[:vp_dbid]}" if data[:vp_dbid]
        # noinspection RubyResolve
        dc.identifier! "uuid:#{data[:vp_uuid]}" if data[:vp_uuid]
        # noinspection RubyResolve
        dc.isPartOf data[:path] if data[:path]
        record.data = dc.to_xml
        ie.metadata_record = record
        debug "Created IE for '#{ie_info(data)}'"
        ie.save!

        created = data[:created]

        if (original = create_file(data[:original][:file], data[:original][:size], data[:name], created, data[:checksum]))
          original.properties['rep_type'] = 'original'
          original.save!
          ie << original
          ie.save!
          debug "Added original file to IE", ie
        else
          raise WorkflowError, "Failed to create original FileItem for IE '#{ie_info(data)}'"
        end

        if (derived = create_file(data[:derived][:file], data[:derived][:size], (data[:deriv_name] || data[:name]), created))
          derived.properties['rep_type'] = 'derived'
          derived.save!
          ie << derived
          ie.save!
          debug "Added derived file to IE", ie
        end if data[:derived] &&
            !(data[:derived][:mime] == data[:original][:mime] && data[:derived][:size] == data[:original][:size]) &&
            data[:derived][:size] > 0

        if data[:thumbnail]&.any?
          fname = "#{File.basename data[:name]}#{File.extname data[:thumbnail][:file]}"
          if (thumbnail = create_file(data[:thumbnail][:file], data[:thumbnail][:size], fname, created))
            thumbnail.properties['rep_type'] = 'thumbnail'
            thumbnail.save!
            ie << thumbnail
            ie.save!
            debug "Added thumbnail file to IE", ie
          end
        end

      end

      def ie_info(ie)
        "#{ie[:name]} [#{ie[:vp_dbid]&.to_s || ie[:vp_uuid]}]"
      end

    end

  end
end
