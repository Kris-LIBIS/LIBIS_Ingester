# encoding: utf-8
require 'rspec'
require 'stringio'
require_relative 'spec_helper'

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'libis/ingester'
require 'libis/ingester/installer'

require_relative 'data'

describe 'Test' do

  before(:all) do
    config_file = File.join(Libis::Ingester::ROOT_DIR, 'site.config.yml')
    installer = ::Libis::Ingester::Installer.new(config_file)
    installer.seed_database
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

  let(:job_name) { 'E-Thesis' }

  it 'test job' do
    run = job.execute
    puts logoutput.string.lines unless print_log
    expect(run.status).to be :DONE
    list_data(run)
  end

end

