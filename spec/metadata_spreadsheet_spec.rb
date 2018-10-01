require 'rspec'
require_relative 'spec_helper'

require 'libis-tools'
require 'libis-metadata'

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'libis/ingester'
require 'libis/ingester/initializer'
require 'libis/ingester/tasks/metadata_spreadsheet_mapper'

describe 'MetadataSpreadsheetMapper' do

  before(:all) do
    config_file = File.join(Libis::Ingester::ROOT_DIR, 'site.config.yml')
    initializer = ::Libis::Ingester::Initializer.init(config_file)
    initializer.database.clear
    initializer.seed_database
  end

  let(:task) {
    task = Libis::Ingester::MetadataSpreadsheetMapper.new nil, 'name' => 'Mapper'
    task.apply_options(task_options)
    run << task
    task
  }

  let(:task_options) {
    {
        'Mapper' => {
            'item_types' => %w'Libis::Workflow::FileItem',
            'title_to_name' => true,
            'title_to_label' => true,
            'fail_on_missing' => true,
            'mapping_file' => mapping_file,
            'mapping_format' => 'xls',
            'filter_keys' => [],
            'filter_values' => [],
            'ignore_empty_value' => false,
            'mapping_headers' => %w'objectname filename label',
            'mapping_key' => 'filename',
            'mapping_value' => nil,
            'term' => nil,
            'match_regex' => nil,
            'match_term' => 'item.name',
        }
    }
  }

  let(:mapping_file) { File.join(File.dirname(__FILE__), 'data', 'MetadataMappingSample.xlsx') }

  let(:run) {
    run = Libis::Workflow::Run.new
    run.job = job
    run
  }

  let(:job) {
    job = Libis::Workflow::Job.new
  }

  let(:item) {
    item = Libis::Workflow::FileItem.new
    item.filename = filename
    run << item
    def item.reload; end
    def item.reload_relations; end
    def item.metadata_record=(record); @metadata = record; end
    def item.metadata_record; @metadata; end
    item
  }
  # let (:filename) { File.join(File.dirname(__FILE__), 'test_data', 'test.pdf') }

  context 'singe file' do
    let (:filename) { File.join(File.dirname(__FILE__), 'test_data', 'test.pdf') }
    let(:mapping_file) { File.join(File.dirname(__FILE__), 'data', 'MetadataMappingSample.xlsx|folios') }

    it 'should set metadata' do
      task.run(item)
      # noinspection RubyResolve
      record = item.metadata_record
      expect(record).not_to be_nil
      expect(record).to be_a(Libis::Ingester::MetadataRecord)
      record = Libis::Metadata::DublinCoreRecord.new(record.data)
      expect(record['//title']).to eq 'test (PDF)'
      expect(record['//description']).to eq 'PDF file for Ingester testing'
    end
  end

end

