# encoding: utf-8
require 'rspec'
require 'stringio'
require_relative 'spec_helper'

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'libis/ingester'

require_relative 'data'

describe 'Ingester' do

  before(:all) do
    # noinspection RubyResolve
    ::Libis::Ingester.configure do |cfg|
      cfg.workdir = File.join(Libis::Ingester::ROOT_DIR, 'spec', 'work', 'scrap')
      cfg.database_connect 'mongoid.yml', :test
    end
    ::Libis::Ingester::Workflow.each { |wf| wf.destroy }
    ::Libis::Ingester::Config.require_all File.join(Libis::Ingester::ROOT_DIR, 'spec', 'tasks')
    ::Libis::Ingester::Database.new(nil, :test).clear.setup.setup(File.join(Libis::Ingester::ROOT_DIR, 'spec', 'seed'))
  end

  let(:datadir) { File.join(Libis::Ingester::ROOT_DIR, 'spec', 'test_data') }
  let(:logoutput) { StringIO.new }
  let(:print_log) { true }
  let(:workflow) {
    ::Libis::Ingester.configure do |cfg|
      cfg.logger = ::Logger.new(print_log ? STDOUT : logoutput)
      cfg.set_log_formatter
      cfg.logger.level = Logger::DEBUG
    end
    ::Libis::Ingester::Workflow.find_by name: wf_name
  }

  # context 'ParameterTest' do
  #
  #   let(:wf_name) { 'ParameterTestIngest' }
  #
  #   it 'set no parameters at run-time' do
  #     run = workflow.run
  #     expect(run.status).to be :DONE
  #     expect(run.tasks[0].parameter(:param1)).to be_nil
  #     expect(run.tasks[0].parameter(:param2)).to eq 'set in input'
  #     expect(run.tasks[0].parameter(:param3)).to eq 'set in input'
  #     expect(run.tasks[0].parameter(:param4)).to eq 'set in task config'
  #     expect(run.tasks[0].parameter(:param5)).to eq 'set in task definition'
  #     expect(run.tasks[0].parameter(:param6)).to eq 'set in input'
  #     expect(run.tasks[0].parameter(:param7)).to eq 'set in input'
  #     expect(run.tasks[0].parameter(:param8)).to eq 'set in task config'
  #   end
  #
  #   it 'set parameters at run-time' do
  #     run = workflow.run(
  #         param1: 'set at run-time',
  #         param2: 'set at run-time',
  #         param3: 'set at run-time',
  #         param4: 'set at run-time',
  #         param5: 'set at run-time',
  #         param6: 'set at run-time',
  #         param7: 'set at run-time',
  #         param8: 'set at run-time',
  #     )
  #     expect(run.status).to be :DONE
  #     expect(run.tasks[0].parameter(:param1)).to eq 'set at run-time'
  #     expect(run.tasks[0].parameter(:param2)).to eq 'set at run-time'
  #     expect(run.tasks[0].parameter(:param3)).to eq 'set at run-time'
  #     expect(run.tasks[0].parameter(:param4)).to eq 'set at run-time'
  #     expect(run.tasks[0].parameter(:param5)).to eq 'set at run-time'
  #     expect(run.tasks[0].parameter(:param6)).to eq 'set at run-time'
  #     expect(run.tasks[0].parameter(:param7)).to eq 'set at run-time'
  #     expect(run.tasks[0].parameter(:param8)).to eq 'set at run-time'
  #   end
  #
  # end

  # context 'DirCollector' do
  #
  #   let(:wf_name) { 'SimpleTestIngest' }
  #
  #   it 'collect top level files' do
  #     run = workflow.run location: datadir
  #     expect(run.items.count).to be 1
  #     expect(run.items[0].name).to eq 'test.pdf'
  #   end
  #
  #   it 'collect files recursively' do
  #     run = workflow.run location: datadir, subdirs: 'recursive'
  #     expect(run.items.count).to be FILES_RECURSIVE.count
  #     expect(run.items.map { |item| item.filepath.gsub(datadir+'/', '') }).to eq FILES_RECURSIVE
  #   end
  #
  #   it 'collect files in collections' do
  #     run = workflow.run location: datadir, subdirs: 'collection'
  #     expect(run.items.count).to be 2
  #     check_data(run, FILES_TREE + [run.name])
  #     expect(run.items[0]).to be_a(Libis::Ingester::Collection)
  #   end
  #
  #   it 'collect files in divisions' do
  #     run = workflow.run location: datadir, subdirs: 'complex'
  #     expect(run.items.count).to be 2
  #     check_data(run, FILES_TREE + [run.name])
  #     expect(run.items[0]).to be_a(Libis::Ingester::Division)
  #   end
  #
  # end

  # context 'With file grouping' do
  #   let(:wf_name) { 'FileGroupingTest' }
  #
  #   it 'in collections' do
  #     run = workflow.run location: datadir
  #     expect(run.items.count).to be 2
  #     check_data(run, FILES_GROUP + [run.name])
  #     expect(run.items[0]).to be_a(Libis::Ingester::Collection)
  #   end
  #
  # end

  # context 'with FileGrouper and IeBuilder' do
  #
  #   let(:wf_name) { 'IeBuilderTest' }
  #
  #   it 'in collections' do
  #     run = workflow.run location: datadir
  #     expect(run.items.count).to be 2
  #     check_data(run, FILE_WITH_IE_COLLECTIONS + [run.name])
  #     expect(run.items[0]).to be_a(Libis::Ingester::Collection)
  #     expect(run.items[1]).to be_a(Libis::Ingester::IntellectualEntity)
  #   end
  #
  #   it 'in complex IE' do
  #     run = workflow.run location: datadir, subdirs: 'complex'
  #     expect(run.items.count).to be 2
  #     check_data(run, FILE_WITH_IE_COMPLEX + [run.name])
  #     expect(run.items[0]).to be_a(Libis::Ingester::IntellectualEntity)
  #     expect(run.items[1]).to be_a(Libis::Ingester::IntellectualEntity)
  #   end
  #
  # end

  context 'Complex ingest' do

    let(:print_log) { true }
    let(:wf_name) { 'Complex test ingest' }
    let(:md5_file) { File.join(Libis::Ingester::ROOT_DIR, 'spec', 'test_data.md5') }
    let(:ingest_dir) { File.join(Libis::Ingester::ROOT_DIR, 'spec', 'work', 'ingest') }

    it do
      run = workflow.run location: datadir, checksum_file: md5_file, ingest_dir: ingest_dir, filename_match: '^(abc|def|test)'

      puts logoutput.string.lines
      expect(run.status).to be :DONE
      list_data(run)
      run.items.each { |item| check_list(item, COMPLEX_INGEST, 1) }
    end
  end

end

