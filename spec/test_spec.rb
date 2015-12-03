# encoding: utf-8
require 'rspec'
require 'stringio'
require_relative 'spec_helper'

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'libis/ingester'

require_relative 'data'

describe 'Test' do

  before(:all) do
    # noinspection RubyResolve
    ::Libis::Ingester.configure do |cfg|
      cfg.workdir = File.join(Libis::Ingester::ROOT_DIR, 'spec', 'work', 'scrap')
      cfg.database_connect 'mongoid.yml', :test
      cfg.base_url = 'http://libis-p-rosetta-3w.cc.kuleuven.be:1801'
      cfg.pds_url = 'http://libis-p-rosetta-3w.cc.kuleuven.be:8991'
    end
    ::Libis::Ingester::Workflow.each { |wf| wf.destroy }
    ::Libis::Ingester::Config.require_all File.join(Libis::Ingester::ROOT_DIR, 'spec', 'tasks')
    ::Libis::Ingester::Database.new(nil, :test).clear.setup(File.join(Libis::Ingester::ROOT_DIR, 'spec', 'seed'))
  end

  let(:config_logger) {
    ::Libis::Ingester.configure do |cfg|
      cfg.logger = ::Logger.new(print_log ? STDOUT : logoutput)
      cfg.set_log_formatter
      cfg.logger.level = Logger::DEBUG
    end
  }
  let(:print_log) { true }
  let(:logoutput) { StringIO.new }

  let(:job) {
    config_logger
    Libis::Ingester::Job.find_by name: job_name
  }

  let(:job_name) { 'KADOC - Kerk en Leven' }

  it 'test job' do
    run = job.execute
    puts logoutput.string.lines
    expect(run.status).to be :DONE
    list_data(run)
  end

end

