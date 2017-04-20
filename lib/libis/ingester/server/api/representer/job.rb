require_relative 'base'

module Libis::Ingester::API::Representer
  class Job < Grape::Roar::Decorator
    include Base

    type :jobs

    attributes do
      property :name, type: String, desc: 'job name'
      property :description, type: String, desc: 'job description'

      nested :log do
        property :log_to_file, as: :to_file, type: Boolean, desc: 'write log to a file'
        property :log_each_run, as: :each_run, type: Boolean, desc: 'create new log file for each run'
        property :log_level, as: :level, type: String,
                 values: %w(FATAL ERROR WARN INFO DEBUG), default: 'DEBUG', desc: 'log verbosity level'
        property :log_age, as: :age, type: String,
                 values: %w(hourly daily weekly monthly), default: 'daily', desc: 'log rotation frequency'
        property :log_keep, as: :keep, type: Integer,
                 values: [1..10], default: 5, desc: 'number of old rotations to keep'
      end

      property :material_flow, type: String, desc: 'material flow name (as defined in organization)'

      property :input, type: Hash, desc: 'default parameter input values'

    end

    # noinspection RubyResolve
    link :ingest_model do |opts|
      "#{opts[:base_url]}/ingest_models/#{represented.ingest_model_id}"
    end

    # noinspection RubyResolve
    link :organization do |opts|
      "#{opts[:base_url]}/organizations/#{represented.organization_id}"
    end

    # noinspection RubyResolve
    link :workflow do |opts|
      "#{opts[:base_url]}/workflows/#{represented.workflow_id}"
    end

  end
end