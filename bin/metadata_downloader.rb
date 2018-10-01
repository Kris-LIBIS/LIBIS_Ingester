#!/usr/bin/env ruby

require 'uri'
require 'tty-prompt'
require 'pathname'

require 'libis/services/alma/sru_service'
require 'libis/services/scope/search'

require 'libis/metadata/marc21_record'
require 'libis/metadata/dublin_core_record'
require 'libis/tools/xml_document'
require 'libis/tools/extend/string'

require 'libis/metadata/mappers/kuleuven'
require 'libis/metadata/mappers/scope'

class MetadataDownloader

  attr_reader :prompt, :service, :mapper_class, :config, :md_update

  def initialize
    @prompt = TTY::Prompt.new
    @service = nil
    @mapper_class = nil
    @config = {}
    @md_update = false
    @target_dir = '.'
  end

  def configure
    service = prompt.select 'Select the metadata source:', %w'alma scope'
    case service
    when 'alma'
      @service = Libis::Services::Alma::SruService.new
      @mapper_class = Libis::Metadata::Mappers::Kuleuven
      config[:field] = prompt.ask 'Alma field to search', default: 'alma.mms_id'
      config[:library] = prompt.ask 'Library code', default: '32KUL_KUL'
    when 'scope'
      @service = ::Libis::Services::Scope::Search.new
      @mapper_class = Libis::Metadata::Mappers::Scope
      config[:field] = prompt.select 'Scope field to search', %w'REPCODE ID'
      database = prompt.ask 'Database name'
      user = prompt.ask 'User name'
      password = prompt.mask 'Password'
      @service.connect(user, password, database)
    else
      prompt.error "ERROR: unknown service '#{service}'"
      exit(-1)
    end
    @md_update = prompt.yes? 'Generate MD Update job files?'
    @target_dir = tree_select '.',file: false, cycle: false, page_size: 20
  rescue Exception => e
    prompt.error "ERROR: failed to configure metadata service: #{e.message}"
    exit(-1)
  end

  # @return [Libis::Metadata::Marc21Record|Libis::Metadata::DublinCoreRecord]
  def search(term)
    record = case service
             when ::Libis::Services::Alma::SruService
               result = service.search(config[:field], URI::encode("\"#{term}\""), config[:library])
               prompt.warn "WARNING: Multiple records found for #{config[:field]}=#{term}" if result.size > 1
               result.empty? ? nil : ::Libis::Metadata::Marc21Record.new(result.first.root)

             when ::Libis::Services::Scope::Search
               service.query(term, type: config[:field])
               service.next_record do |doc|
                 ::Libis::Metadata::DublinCoreRecord.new(doc.to_xml)
               end

             else
               # nothing

             end

    unless record
      prompt.warn "WARNING: No record found for #{config[:field]} = '#{term}'"
      return nil
    end

    record.extend mapper_class
    record.to_dc

  rescue Exception => e
    prompt.error "ERROR: Search request failed: #{e.message}"
    return nil
  end

  def download
    unless service
      prompt.error "ERROR: metadata service not configured"
    end
    while (term = prompt.ask 'Search value:')
      record = search(term)
      if record
        if @md_update
          term = prompt.ask 'IE PID to update:'
          record = md_update_xml(term, record)
        end

        filename = prompt.ask 'File name: ', default: "#{term}.xml"
        record.save File.join(@target_dir, filename)
      end
    end
  end

  NO_DECL = Nokogiri::XML::Node::SaveOptions::FORMAT + Nokogiri::XML::Node::SaveOptions::NO_DECLARATION

  def md_update_xml(pid, record)
    Libis::Tools::XmlDocument.parse <<EO_XML
<updateMD xmlns="http://com/exlibris/digitool/repository/api/xmlbeans">
  <PID>#{pid}</PID>
  <metadata>
    <type>descriptive</type>
    <subType>dc</subType>
    <content>
      <![CDATA[#{record.document.to_xml(save_with: NO_DECL)}]]>
    </content>
  </metadata>
</updateMD>
EO_XML
  end

  def tree_select(cd, file: true, page_size: 22, filter: true, cycle: true)
    cd = Pathname.new(cd) unless cd.is_a? Pathname
    cd  = cd.realpath

    dirs = cd.children.select {|x| x.directory? }.sort
    files = file ? cd.children.select {|x| x.file? }.sort : []

    choices = []
    choices << {name: "<< #{cd} >>", value: cd, disabled: file ? '' : false}
    choices << {name: '[..]', value: cd.parent}

    dirs.each {|d| choices << {name: "[#{d.basename}]", value: d}}
    files.each {|f| choices << {name: f.basename.to_path, value: f}}

    selection = prompt.select "Select #{'file or ' if files}directory:", choices,
                              per_page: page_size, filter: filter, cycle: cycle, default: file ? 2 : 1

    return selection if selection == cd || selection.file?

    tree_select selection, file: file, page_size: page_size, filter: filter, cycle: cycle
  end

end

md = MetadataDownloader.new
md.configure
md.download
