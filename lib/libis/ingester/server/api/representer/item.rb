require_relative 'base'

module Libis::Ingester::API::Representer
  class Item < Grape::Roar::Decorator
    include Base

    type :items

    # -- common attributes and links

    attributes do
      property :_type, as: :type, type: String, desc: 'item type'
      property :name, writable: false, type: String, desc: 'item name'
      property :options, type: Hash, desc: 'Hash of item options'
      property :properties, type: Hash, desc: 'set of item properties'
      property :metadata_record, desc: 'item metadata' do
        property :format, type: String, desc: 'metadata format, typically \'DC\''
        property :data, type: String, desc: 'the metadata'
      end
    end

    link :access_right do |opts|
      "#{opts[:base_url]}/access_rights/#{represented.access_right_id}" if represented.access_right_id
    end

    link :parent do |opts|
      "#{self_url(opts)}/#{represented.parent_id}" if represented.parent_id
    end

    link :items do |opts|
      "#{self_url(opts)}/#{represented.id}/items" if represented.items.count > 0
    end

    # -- for runs
    attributes do
      property :start_date, type: DateTime, desc: 'start date'
      property :log_to_file, type: Boolean, desc: 'write log to file'
      property :log_level, type: String, desc: 'log level'
      property :run_name, type: String, desc: 'identifying run name'
      property :status_log, type: Array, desc: 'list of status updates'
    end

    link :job do |opts|
      # noinspection RubyResolve
      "#{opts[:base_url]}/jobs/#{represented.job_id}" if represented.job_id
    end

    link :ingest_model do |opts|
      # noinspection RubyResolve
      "#{opts[:base_url]}/ingest_models/#{represented.job.ingest_model_id}" if represented.job_id
    end

    link :organization do |opts|
      # noinspection RubyResolve
      "#{opts[:base_url]}/organizations/#{represented.job.organization_id}" if represented.job_id
    end

    link :workflow do |opts|
      # noinspection RubyResolve
      "#{opts[:base_url]}/workflows/#{represented.job.workflow_id}" if represented.job_id
    end

    # -- Collection

    attributes do
      property :navigate, type: Boolean, desc: 'allow navigation'
      property :publish, type: Boolean, desc: 'allow publishing via OAI-PMH'
      property :description, type: String, desc: 'detailed description'
      property :identifier, desc: 'external identifier' do
        property :external_system, as: :system, type: String, desc: 'system'
        property :external_id, as: :id, type: String, desc: 'id'
      end
    end

    # -- IntellectualEntity

    attributes do
      property :ingest_type, type: String, desc: 'type of ingest'
      property :pid, type: String, desc: 'the PID associated to the IE after ingest'
    end

    link :retention_period do |opts|
      # noinspection RubyResolve
      "#{opts[:base_url]}/retention_periods/#{represented.retention_period_id}" if represented.retention_period_id
    end

    # -- Representation

    link :representation_info do |opts|
      # noinspection RubyResolve
      "#{opts[:base_url]}/representation_infos/#{represented.representation_info_id}" if represented.representation_info_id
    end

    # -- Division

    # -- DirItem

    # -- FileItem

  end
end

