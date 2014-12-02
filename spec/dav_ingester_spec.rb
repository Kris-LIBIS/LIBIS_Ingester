# encoding: utf-8
require 'rspec'
require 'stringio'
require 'LIBIS_Workflow_Mongoid'

require_relative 'spec_helper'
require_relative 'data'

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'libis/ingester'

SIPDIR = File.absolute_path(File.join(File.dirname(__FILE__), '..', 'data', 'SIP'))

def get_flow
  @dav_mets = LIBIS::Ingester::Flow.find_by(name: 'DAVIngestMETS2')
end

def setup_flow
  # LIBIS::Ingester::Flow.each { |wf| wf.destroy }
  get_flow
  return unless @dav_mets.nil?
  @dav_mets = LIBIS::Ingester::Flow.new
  @dav_mets.configure(
      name: 'DAVIngestMETS2',
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
          },
          {
              name: 'PreIngest',
              tasks: [
                  {
                      class: 'LIBIS::Ingester::DavIngestPreparer',
                  }
              ]
          },
          {
              name: 'Ingest',
              tasks: [
                  {
                      class: 'LIBIS::Ingester::Submitter',
                  }
              ]
          },
      ],
      input: {
          folder: {default: SIPDIR, propagate_to: 'DavSipCollector#location'},
          ingest_type: {default: 'METS', propagate_to: 'DavSipCollector'},
          access_right: {default: 'AR_EVERYONE', propagate_to: 'DavIngestPreparer'},
          login_name: {default: nil, propagate_to: 'Submitter'},
          login_pass: {default: nil, propagate_to: 'Submitter'},
          login_inst: {default: nil, propagate_to: 'Submitter'},
          flow_id: {default: nil, propagate_to: 'Submitter'},
          producer_id: {default: nil, propagate_to: 'Submitter'},
      }
  )
  @dav_mets.save
end

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

    setup_flow

  end

  # it 'should collect all files in collection groups' do
  #   puts @logoutput.string
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

  # it 'should read all files in poc1' do
  #   puts @logoutput.string
  #   run = @dav_mets.run(
  #     folder: '/nas/vol04/upload/flandrica/DAV/poc1',
  #     ingest_type: 'METS', access_right: '361545',
  #     login_name: 'dav_poc1', login_pass: 'rH4uQhY6', login_inst: 'ROSETTA_DAVPOC1',
  #   )
  #   list_data(run)
  # end

  # it 'should read all files in poc2' do
  #   puts @logoutput.string
  #   run = @dav_mets.run(
  #       folder: '/nas/vol04/upload/flandrica/DAV/poc2',
  #       ingest_type: 'METS', access_right: '361546',
  #       login_name: 'dav_poc2', login_pass: 'Z3Et5mZ7', login_inst: 'ROSETTA_DAVPOC2',
  #       flow_id: '91018905', producer_id: '91019864'
  #   )
  #   list_data(run)
  # end

  # it 'should resubmit poc2' do
  #   run = LIBIS::Ingester::Run.find_by(created_at: DateTime.parse('2014-11-03T15:10:10.121+01:00'))
  #   run.restart 'Ingest'
  # end

  # it 'should read all files in poc3' do
  #   puts @logoutput.string
  #   run = @dav_mets.run(
  #       folder: '/nas/vol04/upload/flandrica/DAV/poc3',
  #       ingest_type: 'METS', access_right: '361547',
  #       login_name: 'dav_poc3', login_pass: 'W5wbXeF7', login_inst: 'ROSETTA_DAVPOC3',
  #       flow_id: '88375579', producer_id: '100531736'
  #   )
  #   list_data(run)
  # end

  # it 'should restart last run' do
  #   run = LIBIS::Ingester::Run.last
  #   run.restart 'Ingest'
  # end

  # it 'should restart poc1' do
  #   run = LIBIS::Ingester::Run.last
  #   run.restart 'PreIngest'
  # end

  it 'should create a sub-dir' do
    puts @logoutput.string
    run = @dav_mets.run(
        folder: '/nas/vol04/upload/flandrica/DAV/poc3/000003',
        ingest_type: 'METS', access_right: '361547',
        login_name: 'dav_poc3', login_pass: 'W5wbXeF7', login_inst: 'ROSETTA_DAVPOC3',
        flow_id: '88375579', producer_id: '100531736'
    )
    # list_data(run)
  end

end

