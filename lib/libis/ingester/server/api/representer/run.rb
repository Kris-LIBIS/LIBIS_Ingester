require_relative 'base'

module Libis::Ingester::API::Representer
  class Run < Grape::Roar::Decorator
    include Base

    type :runs

    # -- common attributes and links

    attributes do
      property :name, writable: false, type: String, desc: 'item name'
      property :options, type: Hash, desc: 'Hash of item options'
      property :properties, type: Hash, desc: 'set of item properties'

      property :start_date, type: DateTime, desc: 'start date'
      property :log_to_file, type: Boolean, desc: 'write log to file'
      property :log_level, type: String, desc: 'log level'
      property :log_filename, type: String, desc: 'name of the log file'
      property :run_name, type: String, desc: 'identifying run name'
      property :status_log, type: Array, desc: 'list of status updates'

      property :ingest_dir, writable: false, type: String, desc: 'ingest dir'
    end

    link :job do |opts|
      # noinspection RubyResolve
      "#{opts[:base_url]}/jobs/#{represented.job_id}" if represented.job_id
    end

    link :items do |opts|
      "#{self_url(opts)}/#{represented.id}/items" if represented.items.count > 0
    end

    # link :ingest_model do |opts|
    #   # noinspection RubyResolve
    #   "#{opts[:base_url]}/ingest_models/#{represented.job.ingest_model_id}" if represented.job_id
    # end
    #
    # link :organization do |opts|
    #   # noinspection RubyResolve
    #   "#{opts[:base_url]}/organizations/#{represented.job.organization_id}" if represented.job_id
    # end
    #
    # link :workflow do |opts|
    #   # noinspection RubyResolve
    #   "#{opts[:base_url]}/workflows/#{represented.job.workflow_id}" if represented.job_id
    # end

  end
end

