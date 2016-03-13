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
    ::Libis::Ingester::Run.each do |run|
      puts ' x ' + run.name
      run.destroy!
    end
    # installer.database.clear
    installer.seed_database
  end

  let(:job) {
    Libis::Ingester::Job.find_by name: job_name
  }

  # let(:job_name) { 'KADOC - Kerk en Leven' }
  let(:job_name) { 'E-Thesis' }

  it 'test job' do
    run = job.execute
    expect(run.status).to be :DONE
    list_data(run)
  end

end

