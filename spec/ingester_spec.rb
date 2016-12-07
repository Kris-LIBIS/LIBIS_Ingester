# encoding: utf-8
require 'rspec'
require 'stringio'
require_relative 'spec_helper'

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'libis/ingester'
require 'libis/ingester/initializer'

require_relative 'data'

describe 'Ingester' do

  before(:all) do
    config_file = File.join(Libis::Ingester::ROOT_DIR, 'site.config.yml')
    initializer = ::Libis::Ingester::Initializer.init(config_file)
    initializer.database.clear
    initializer.seed_database
  end

  let(:datadir) { File.join(Libis::Ingester::ROOT_DIR, 'spec', 'test_data') }
  let(:job) {
    Libis::Ingester::Job.find_by name: job_name
  }


  context 'ParameterTest' do

    let(:print_log) { false }
    let(:job_name) { 'Parameter Test Job' }

    it 'set no parameters at run-time' do
      run = job.execute
      expect(run.status).to be :DONE
      expect(run.tasks[0].parameter(:param1)).to be_nil
      expect(run.tasks[0].parameter(:param2)).to eq 'set in input'
      expect(run.tasks[0].parameter(:param3)).to eq 'set in input'
      expect(run.tasks[0].parameter(:param4)).to eq 'set in task config'
      expect(run.tasks[0].parameter(:param5)).to eq 'set in task definition'
      expect(run.tasks[0].parameter(:param6)).to eq 'set in input'
      expect(run.tasks[0].parameter(:param7)).to eq 'set in input'
      expect(run.tasks[0].parameter(:param8)).to eq 'set in task config'
    end

    it 'set parameters at run-time' do
      run = job.execute(
          param1: 'set at run-time',
          param2: 'set at run-time',
          param3: 'set at run-time',
          param4: 'set at run-time',
          param5: 'set at run-time',
          param6: 'set at run-time',
          param7: 'set at run-time',
          param8: 'set at run-time',
      )
      expect(run.status).to be :DONE
      expect(run.tasks[0].parameter(:param1)).to eq 'set at run-time'
      expect(run.tasks[0].parameter(:param2)).to eq 'set at run-time'
      expect(run.tasks[0].parameter(:param3)).to eq 'set at run-time'
      expect(run.tasks[0].parameter(:param4)).to eq 'set at run-time'
      expect(run.tasks[0].parameter(:param5)).to eq 'set at run-time'
      expect(run.tasks[0].parameter(:param6)).to eq 'set at run-time'
      expect(run.tasks[0].parameter(:param7)).to eq 'set at run-time'
      expect(run.tasks[0].parameter(:param8)).to eq 'set at run-time'
    end

  end

  context 'DirCollector' do

    let(:print_log) { true }
    let(:job_name) { 'Simple Test Job' }

    it 'collect top level files' do
      run = job.execute location: datadir
      expect(run.items.size).to be 1
      expect(run.items.count).to be 1
      expect(run.items[0].filename).to eq 'test.pdf'
    end

    it 'collect files recursively' do
      run = job.execute location: datadir, subdirs: 'recursive'
      expect(run.items.count).to be FILES_RECURSIVE.count
      expect(run.get_items.map { |item| item.filepath.gsub(datadir+'/', '') }).to eq FILES_RECURSIVE
    end

    it 'collect files in collections' do
      run = job.execute location: datadir, subdirs: 'collection'
      check_data(run, FILES_TREE + [run.name], print_log)
      expect(run.items.count).to be 2
      expect(run.items[0]).to be_a(Libis::Ingester::Collection)
    end

    it 'collect files in divisions' do
      run = job.execute location: datadir, subdirs: 'complex'
      expect(run.items.count).to be 2
      check_data(run, FILES_TREE + [run.name], print_log)
      expect(run.items[0]).to be_a(Libis::Ingester::Division)
    end

  end

  context 'With file grouping' do

    let(:print_log) { false }
    let(:job_name) { 'File Grouping Test' }

    it 'in collections' do
      run = job.execute location: datadir
      expect(run.items.count).to be 2
      check_data(run, FILES_GROUP + [run.name], print_log)
      expect(run.items[0]).to be_a(Libis::Ingester::Collection)
    end

  end

  context 'with FileGrouper and IeBuilder' do

    let(:print_log) { false }
    let(:job_name) { 'IeBuilder Test' }

    it 'in collections' do
      run = job.execute location: datadir
      expect(run.items.count).to be 2
      check_data(run, FILE_WITH_IE_COLLECTIONS + [run.name], print_log)
      expect(run.items[0]).to be_a(Libis::Ingester::Collection)
      expect(run.items[1]).to be_a(Libis::Ingester::IntellectualEntity)
    end

    it 'in complex IE' do
      run = job.execute location: datadir, subdirs: 'complex'
      expect(run.items.count).to be 2
      check_data(run, FILE_WITH_IE_COMPLEX + [run.name], print_log)
      expect(run.items[0]).to be_a(Libis::Ingester::IntellectualEntity)
      expect(run.items[1]).to be_a(Libis::Ingester::IntellectualEntity)
    end

  end

  context 'complext ingest' do

    let(:print_log) { false }
    let(:job_name) { 'Complex Test Job' }

    it 'run the ingest' do
      run = job.execute
      expect(run.status).to be :DONE
    end

  end

end

