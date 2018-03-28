# encoding: utf-8
require 'rspec'
require 'stringio'
require 'awesome_print'

require_relative 'spec_helper'


$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'libis/ingester'
require 'libis/ingester/initializer'
require 'libis/tools/extend/hash'

require_relative 'data'

describe 'Ingester' do

  before(:all) do
    config_file = File.join(Libis::Ingester::ROOT_DIR, 'site.config.yml')
    initializer = ::Libis::Ingester::Initializer.init(config_file)
    initializer.database.clear
    initializer.seed_database
  end

  let(:datadir) {File.join(Libis::Ingester::ROOT_DIR, 'spec', 'test_data')}
  let(:job) {
    Libis::Ingester::Job.find_by name: job_name
  }


  context 'ParameterTest' do

    let(:print_log) {false}
    let(:job_name) {'Parameter Test Job'}

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
      ap run.tasks[0].parameter(:paramxx)
      expect(run.tasks[0].parameter(:paramxx)).to eq Hash[:key1,'value1', :key2, 'value2']

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

    let(:print_log) {true}
    let(:job_name) {'Simple Test Job'}

    it 'collect top level files' do
      run = job.execute location: datadir
      expect(run.items.size).to be 1
      expect(run.items.count).to be 1
      expect(run.items[0].filename).to eq 'test.pdf'
    end

    it 'collect files recursively' do
      run = job.execute location: datadir, subdirs: 'recursive'
      expect(run.items.count).to be FILES_RECURSIVE.count
      expect(run.get_items.map {|item| item.filepath.gsub(datadir + '/', '')}).to eq FILES_RECURSIVE
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

    let(:print_log) {false}
    let(:job_name) {'File Grouping Test'}

    it 'in collections' do
      run = job.execute location: datadir
      expect(run.items.count).to be 2
      check_data(run, FILES_GROUP + [run.name], print_log)
      expect(run.items[0]).to be_a(Libis::Ingester::Collection)
    end

  end

  context 'with FileGrouper and IeBuilder' do

    let(:print_log) {false}
    let(:job_name) {'IeBuilder Test'}

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

  context 'complex ingest' do

    let(:print_log) {false}
    let(:job_name) {'Complex Test Job'}

    it 'run the ingest' do
      run = job.execute
      expect(run.status).to be :DONE
    end

  end

  context 'Format identification' do

    let(:print_log) {true}

    let(:formats) {
      {
          File.join(datadir, 'dir_a1', 'abc.doc') => {
              mimetype: 'application/msword',
              puid: 'fmt/40',
              :alternatives => [
                  {
                      puid: 'fmt/40',
                      mimetype: 'application/msword',
                      source: :droid
                  }, {
                      puid: 'fmt/111',
                      mimetype: nil,
                      source: :fido
                  }
              ]

          },
          File.join(datadir, 'dir_a1', 'def.doc') => {
              mimetype: 'application/msword',
              puid: 'fmt/40',
              :alternatives => [
                  {
                      puid: 'fmt/40',
                      mimetype: 'application/msword',
                      source: :droid
                  }, {
                      puid: 'fmt/111',
                      mimetype: nil,
                      source: :fido
                  }
              ]
          },
          File.join(datadir, 'dir_a2', 'abc-1.jpg') => {
              mimetype: 'image/jpeg',
              puid: 'fmt/43'
          },
          File.join(datadir, 'dir_a2', 'abc-2.jpg') => {
              mimetype: 'image/jpeg',
              puid: 'fmt/43'
          },
          File.join(datadir, 'dir_a2', 'def-1.jpg') => {
              mimetype: 'image/jpeg',
              puid: 'fmt/43'
          },
          File.join(datadir, 'dir_a2', 'def-2.jpg') => {
              mimetype: 'image/jpeg',
              puid: 'fmt/43'
          },
          File.join(datadir, 'test.pdf') => {
              mimetype: 'application/pdf',
              puid: 'fmt/18'
          },
      }
    }

    let(:check_format) {
      proc do |run|
        expect(run.items.size).to eq formats.size
        expect(run.items.count).to eq formats.size
        formats.each_with_index do |(filepath, result), i|
          puts "File.basename(filepath): #{File.basename(filepath)}"
          expect(run.items[i].filename).to eq File.basename(filepath)
          expect(run.items[i].properties['mimetype']).to eq result[:mimetype]
          expect(run.items[i].properties['puid']).to eq result[:puid]
          format_identification = run.items[i].properties['format_identification'].key_strings_to_symbols recursive: true
          if result[:alternatives]
            expect(format_identification[:alternatives].size).to eq result[:alternatives].size
            result[:alternatives].each_with_index do |alternative, j|
              expect(format_identification[:alternatives][j]).to include alternative
            end
          else
            expect(format_identification[:alternatives]).to be_nil
          end
        end
      end
    }

    context 'Directory' do

      let(:job_name) {'Format identification - Dir'}

      it 'identifies all files correctly' do
        run = job.execute location: datadir
        check_format.call run
      end

    end

    context 'In bulk' do

      let(:job_name) {'Format identification - Dir'}

      it 'identifies all files correctly' do
        run = job.execute location: datadir
        check_format.call run
      end

    end

    context 'One file at a time' do

      let(:job_name) {'Format identification - File'}

      it 'identifies all files correctly' do
        run = job.execute location: datadir
        check_format.call run
      end

    end

  end

end


