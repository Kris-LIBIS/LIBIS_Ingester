# encoding: utf-8
require 'rspec'
require 'stringio'
require 'libis-workflow-mongoid'

require_relative 'spec_helper'

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'libis/ingester'

DIRNAME = File.absolute_path(File.join(File.dirname(__FILE__), '..', 'lib'))
DATADIR = File.absolute_path(File.join(File.dirname(__FILE__), '..', 'data', 'test'))
SELECTION = '(n|r)\.rb$'
FILEMATCH = 'r\.rb$'
MIMEMATCH = 'text/plain'

require_relative 'data'

describe 'Ingester' do

  before :all do

    @logoutput = StringIO.new

    ::Libis::Ingester.configure do |cfg|
      cfg.workdir = File.join(File.dirname(__FILE__), 'work')
      cfg.logger = Logger.new @logoutput
      cfg.set_log_formatter
      cfg.logger.level = Logger::DEBUG
      cfg.database_connect 'mongoid.yml', :test
    end

    Libis::Ingester::Flow.each { |wf| wf.destroy }

    @simple_wf = Libis::Ingester::Flow.new
    @simple_wf.configure(
        name: 'SimpleTestIngest',
        description: 'Simple ingest flow for testing',
        tasks: [
            {
                class: 'Libis::Ingester::DirCollector',
                location: DATADIR,
            },
        ],
        input: {
            subdirs: { default: 'recursive', propagate_to: 'DirCollector' },
            group_match: { default: nil, propagate_to: 'DirCollector' },
            group_label: { default: nil, propagate_to: 'DirCollector' },
            group_file: { default: nil, propagate_to: 'DirCollector' },
        }
    )
    @simple_wf.save

    @workflow = Libis::Ingester::Flow.new
    @workflow.configure(
        name: 'TestIngest',
        description: 'Ingest flow for testing',
        tasks: [
            {class: 'Libis::Ingester::DirCollector', location: DIRNAME},
            {name: 'Check', subitems: true, recursive: true, tasks: [
                {name: 'FilenameCheck', class: 'Libis::Ingester::FileChecker'},
                {name: 'MimetypeCheck', class: 'Libis::Ingester::FileChecker'},
                {name: 'ChecksumCheck', class: 'Libis::Ingester::ChecksumTester'},
                {class: 'Libis::Ingester::VirusChecker'},
            ]
            },
        ],
        input: {
            subdirs: {
                description: 'Scan the location recursively for files',
                default: 'recursive', propagate_to: 'DirCollector'
            },
            selection: {
                description: 'Regular expression to match file path against. Only files matching the expresion will be selected.',
                default: nil, propagate_to: 'DirCollector'
            },
            filename_match: {
                description: 'Regular expression to match file name against. Files not matching the expresion will fail.',
                default: nil, propagate_to: 'FilenameCheck#filename_regexp'
            },
            mimetype_match: {
                description: 'Regular expression to match file name against. Files not matching the expresion will fail.',
                default: nil, propagate_to: 'MimetypeCheck#mimetype_regexp'
            },
            checksum_type: {
                description: 'Checksum algorithm to use. Files not matching the expresion will fail.',
                default: nil, propagate_to: 'ChecksumTester'
            },
        }
    )
    @workflow.save

  end

  it 'should collect all files in collection groups' do
    run = @simple_wf.run(subdirs: 'collection', group_match: '([a-z0-9]+)_([0-9]+\.[^.]+)$', group_label: '$1', group_file: '$2')
    expect(run.items.count).to be 4
    check_data(run, FILES_GROUP + [run.name])
  end

  it 'should collect only top-level files' do
    run = @simple_wf.run(subdirs: 'ignore')
    expect(run.items.count).to be 1
    expect(run.items[0].name).to eq 'abc.gif'
  end

  it 'should collect all files recursively' do
    run = @simple_wf.run(subdirs: 'recursive')
    expect(run.items.count).to be FILES_RECURSIVE.count

    expect(run.items.map {|item| item.filepath.gsub(DATADIR+'/','')}).to eq FILES_RECURSIVE
  end

  it 'should collect all files in collections' do
    run = @simple_wf.run(subdirs: 'collection')
    expect(run.items.count).to be 4
    check_data(run, FILES_TREE + [run.name])
  end

  it 'should collect all files in METS divisions' do
    run = @simple_wf.run(subdirs: 'METS')
    expect(run.items.count).to be 4
    check_data(run, FILES_TREE + [run.name])
  end

  it 'should collect all files in complex structure' do
    run = @simple_wf.run(subdirs: 'complex')
    expect(run.items.count).to be 4
    check_data(run, FILES_TREE + [run.name])
  end

  it 'should collect expected files' do
    run = @workflow.run(selection: SELECTION)
    files = Dir.glob(File.join(DIRNAME,'**','*.rb')).select {|x| x =~ Regexp.new(SELECTION)}.sort

    expect(run.items.count).to be files.count
    run.items.each do |item|
      f = files.delete(item.filepath)
      expect(f).to_not be nil
      expect(item.name).to eq File.basename(f)
    end
  end

end

