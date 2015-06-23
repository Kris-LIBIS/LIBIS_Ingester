# encoding: utf-8
require 'rspec'
require 'stringio'
require_relative 'spec_helper'

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'libis/ingester'

Dir.new(File.absolute_path(File.join(__FILE__, '..', '..', 'lib', 'libis', 'ingester', 'tasks'))).entries.each do |filename|
  next if File.basename(filename) =~ /^\.{1,2}$/
  next unless File.extname(filename) == '.rb'
  # noinspection RubyResolve
  require "libis/ingester/tasks/#{filename}"
end

require_relative 'data'

describe 'Ingester' do

  let(:datadir) { File.absolute_path(File.join(File.dirname(__FILE__), 'test_data')) }
  let(:logoutput) { StringIO.new }
  let(:workflow) {
    # noinspection RubyResolve
    ::Libis::Ingester.configure do |cfg|
      cfg.workdir = File.join(File.dirname(__FILE__), 'work')
      # cfg.logger = Logger.new(logoutput)
      cfg.set_log_formatter
      cfg.logger.level = Logger::DEBUG
      cfg.database_connect 'mongoid.yml', :test
    end

    Libis::Ingester::Flow.each { |wf| wf.destroy }

    wf = ::Libis::Ingester::Flow.new
    wf.configure wf_config
    wf.save
    wf
  }

  context 'DirCollector' do

    let(:wf_config) { {
        name: 'SimpleTestIngest',
        description: 'Simple ingest flow for testing',
        tasks: [
            {
                class: Libis::Ingester::DirCollector.to_s,
                location: datadir,
                recursive: false
            },
        ],
        input: {
            subdirs: {default: 'ignore', propagate_to: 'DirCollector'},
        }
    } }

    it 'collect top level files' do
      run = workflow.run
      expect(run.items.count).to be 1
      expect(run.items[0].name).to eq 'test.pdf'
    end

    it 'collect files recursively' do
      run = workflow.run subdirs: 'recursive'
      expect(run.items.count).to be FILES_RECURSIVE.count
      expect(run.items.map { |item| item.filepath.gsub(datadir+'/', '') }).to eq FILES_RECURSIVE
    end

    it 'collect files in collections' do
      run = workflow.run subdirs: 'collection'
      expect(run.items.count).to be 2
      check_data(run, FILES_TREE + [run.name])
      expect(run.items[0]).to be_a(Libis::Ingester::Collection)
    end

    it 'collect files in divisions' do
      run = workflow.run subdirs: 'complex'
      expect(run.items.count).to be 2
      check_data(run, FILES_TREE + [run.name])
      expect(run.items[0]).to be_a(Libis::Ingester::Division)
    end

  end

  context 'With file grouping' do
    let(:wf_config) { {
        name: 'FileGroupingTest',
        description: 'Ingest flow to test file grouping',
        tasks: [
            {
                class: Libis::Ingester::DirCollector.to_s,
                location: datadir,
                subdirs: 'collection'
            },
            {
                class: Libis::Ingester::FileGrouper.to_s,
                recursive: true,
                group_regex: '^(.+)-(\d*)\.jpg$',
                group_label: '"book-" + $1',
                file_label: '"page-" + $2'
            }
        ],
    } }

    it 'in collections' do
      run = workflow.run
      expect(run.items.count).to be 2
      check_data(run, FILES_GROUP + [run.name])
      expect(run.items[0]).to be_a(Libis::Ingester::Collection)
    end

  end

  context 'with FileGrouper and IeBuilder' do

    let(:wf_config) { {
        name: 'IeBuilderTest',
        description: 'Ingest flow to test IE builder',
        tasks: [
            {
                class: Libis::Ingester::DirCollector.to_s,
                location: datadir,
            },
            {
                class: Libis::Ingester::FileGrouper.to_s,
                recursive: true,
                group_regex: '^(.+)-(\d*)\.jpg$',
                group_label: '"book-" + $1',
                file_label: '"page-" + $2'
            },
            {
                class: Libis::Ingester::IeBuilder.to_s,
            }
        ],
        input: {
            subdirs: {default: 'collection', propagate_to: 'DirCollector'}
        }
    } }

    it 'in collections' do
      run = workflow.run
      expect(run.items.count).to be 2
      check_data(run, FILE_WITH_IE_COLLECTIONS + [run.name])
      expect(run.items[0]).to be_a(Libis::Ingester::Collection)
      expect(run.items[1]).to be_a(Libis::Ingester::IntellectualEntity)
    end

    it 'in complex IE' do
      run = workflow.run subdirs: 'complex'
      expect(run.items.count).to be 2
      check_data(run, FILE_WITH_IE_COMPLEX + [run.name])
      expect(run.items[0]).to be_a(Libis::Ingester::IntellectualEntity)
      expect(run.items[1]).to be_a(Libis::Ingester::IntellectualEntity)
    end

  end

  context 'Complex ingest' do

    let(:wf_config) { {
        name: 'TestIngest',
        description: 'Ingest flow for testing',
        tasks: [
            {class: 'Libis::Ingester::DirCollector', location: datadir, subdirs: 'recursive'},
            {name: 'Check', subitems: true, recursive: false, tasks: [
                {name: 'FilenameCheck', class: 'Libis::Ingester::FileChecker',
                 filename_match: '^(abc|def)'
                 },
                {name: 'ChecksumCheck', class: 'Libis::Ingester::ChecksumTester',
                 checksum_type: :MD5, checksum_file: File.absolute_path(File.join(File.dirname(__FILE__), 'test_data.md5'))},
                {class: 'Libis::Ingester::VirusChecker'},
            ]
            },
            {name: 'PreProcess', subitems: true, recursive: false, tasks: [
                {name: 'FormatIdentifier', class: Libis::Ingester::FormatIdentifier.to_s},
                {name: 'MimetypeCheck', class: 'Libis::Ingester::FileChecker',
                 mimetype_match: nil},
            ]},
            {name: 'PreIngest', subitems: false, recursive: false, tasks: [
                {class: Libis::Ingester::FileGrouper.to_s,
                 recursive: true,
                 group_regex: '^(.+)-(\d*)\.jpg$',
                 group_label: '"book-" + $1',
                 file_label: '"page-" + $2'
                },
                {class: Libis::Ingester::IeBuilder.to_s}
            ]},
            {name: 'Ingest', subitems: false, recursive: false, tasks: [
                {class: Libis::Ingester::IngestBuilder.to_s,
                 ingest_dir: File.join(File.dirname(__FILE__), 'work')
                }
            ]},
        ],
        input: {
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
    } }

    it do
      run = workflow.run
      expect(run.status).to be :DONE
      list_data(run)
    end
  end

end

