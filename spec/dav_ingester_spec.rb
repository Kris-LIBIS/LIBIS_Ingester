# encoding: utf-8
require 'rspec'
require 'stringio'
require 'LIBIS_Workflow_Mongoid'

require_relative 'spec_helper'
require_relative 'data'

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'libis/ingester'

SIPDIR = File.absolute_path(File.join(File.dirname(__FILE__), '..', 'data', 'SIP'))

describe 'DAV Ingester' do

  before :each do
    @logoutput.reopen
  end

  before :all do

    @logoutput = StringIO.new

    ::LIBIS::Ingester.configure do |cfg|
      cfg.workdir = File.join(File.dirname(__FILE__), 'work')
      #cfg.logger = Logger.new @logoutput
      cfg.set_formatter
      cfg.logger.level = Logger::DEBUG
      cfg.database_connect 'mongoid.yml', :test
    end

    LIBIS::Ingester::Flow.each { |wf| wf.destroy }

    @dav_mets = LIBIS::Ingester::Flow.new
    @dav_mets.configure(
        name: 'DAVIngestMETS',
        description: 'DAV Ingest into METS structure.',
        tasks: [
            {
                class: 'LIBIS::Ingester::DavSipCollector',
            },
            {
                name: 'PreProcess',
                subitems: true,
                recursive: true,
                tasks: [
                    {
                        class: 'LIBIS::Ingester::ChecksumTester',
                    },
                    {
                        class: 'LIBIS::Ingester::FormatIdentifier',
                    },
                ]
            }
        ],
        input: {
            folder: { default: SIPDIR, propagate_to: 'DavSipCollector#location'},
            ingest_type: { default: 'METS', propagate_to: 'DavSipCollector' },
        }
    )
    @dav_mets.save

  end

  # it 'should collect all files in collection groups' do
  #   puts @lqogoutput.string
  #   run = @dav_mets.run(collection_type: 'METS')
  #   expect(run.items.count).to be 2
  #   check_data(run, DAV_FILES + [run.name])
  # end
  #
  # it 'should collect all files in collection groups' do
  #   puts @logoutput.string
  #   run = @dav_mets.run(collection_type: 'METS')
  #   expect(run.items.count).to be 2
  #   check_data(run, DAV_FILES + [run.name])
  # end

  it 'should read all files in poc1' do
    puts @logoutput.string
    run = @dav_mets.run(folder: '/nas/vol04/upload/flandrica/DAV/poc1/000001', ingest_type: 'METS')
    list_data(run)
  end

end

