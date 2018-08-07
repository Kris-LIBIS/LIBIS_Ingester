#!/usr/bin/env ruby

require 'uri'
require 'tty-prompt'

require 'libis/services/alma/sru_service'
require 'libis/services/scope/search'

require 'libis/tools/metadata/marc21_record'
require 'libis/tools/metadata/dublin_core_record'

require 'libis/tools/metadata/mappers/kuleuven'
require 'libis/tools/metadata/mappers/scope'

class MetadataDownloader

  attr_reader :prompt, :service, :mapper_class, :config

  def initialize
    @prompt = TTY::Prompt.new
    @service = nil
    @mapper_class = nil
    @config = {}
  end

  def configure
    service = prompt.select 'Select the metadata source:', %w'alma scope'
    case service
    when 'alma'
      @service = Libis::Services::Alma::SruService.new
      @mapper_class = Libis::Tools::Metadata::Mappers::Kuleuven
      config[:field] = prompt.ask 'Alma field to search', default: 'alma.mms_id'
      config[:library] = prompt.ask 'Library code', default: '32KUL_KUL'
    when 'scope'
      @service = ::Libis::Services::Scope::Search.new
      @mapper_class = Libis::Tools::Metadata::Mappers::Scope
      config[:field] = prompt.select 'Scope field to search', %w'REPCODE ID'
      database = prompt.ask 'Database name'
      user = prompt.ask 'User name'
      password = prompt.mask 'Password'
      @service.connect(user, password, database)
    else
      $stderr.puts "ERROR: unknown service '#{service}'"
      exit(-1)
    end
  rescue Exception => e
    $stderr.puts "ERROR: failed to configure metadata service: #{e.message}"
    exit(-1)
  end

  # @return [Libis::Tools::Metadata::DublinCoreRecord]
  def search(term)
    record = case service
             when ::Libis::Services::Alma::SruService
               result = service.search(config[:field], URI::encode("\"#{term}\""), config[:library])
               $stderr.puts "WARNING: Multiple records found for #{config[:field]}=#{term}" if result.size > 1
               result.empty? ? nil : ::Libis::Tools::Metadata::Marc21Record.new(result.first.root)

             when ::Libis::Services::Scope::Search
               service.query(term, type: config[:field])
               service.next_record do |doc|
                 ::Libis::Tools::Metadata::DublinCoreRecord.new(doc.to_xml)
               end

             else
               # nothing

             end

    unless record
      $stderr.puts "WARNING: No record found for #{config[:field]} = '#{term}'"
      return nil
    end

    record.extend mapper_class
    record.to_dc

  rescue Exception => e
    $stderr.puts "ERROR: Search request failed: #{e.message}"
    return nil
  end

  def download
    unless service
      $stderr.puts "ERROR: metadata service not configured"
    end
    while (term = prompt.ask 'Search value:')
      record = search(term)
      if record
        filename = prompt.ask 'File name: ', default: "#{term}.xml"
        record.save(filename)
      end
    end
  end

end

md = MetadataDownloader.new
md.configure
md.download
