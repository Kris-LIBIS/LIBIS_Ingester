# encoding: utf-8
require 'rspec'
require 'stringio'
require_relative 'spec_helper'

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'libis/ingester'
require 'libis/ingester/initializer'

require_relative 'data'

describe 'Test' do

  before(:all) do
    config_file = File.join(Libis::Ingester::ROOT_DIR, 'site.config.yml')
    initializer = ::Libis::Ingester::Initializer.init(config_file)
    initializer.seed_database
  end

  let(:job) {
    Libis::Ingester::Job.find_by name: job_name
  }

  let(:job_name) { 'E-Thesis' }
  # let(:job_name) { 'KADOC - Kerk en Leven' }

  it 'retry run' do
    # noinspection RubyResolve
    run = job.runs.last
    run.execute 'action' => :retry
    expect(run.status).to be :DONE
    list_data(run)
  end

end

