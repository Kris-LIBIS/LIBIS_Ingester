require_relative 'base'

module Libis::Ingester::API::Representer
  class IngestModel < Grape::Roar::Decorator
    include Base

    type :ingest_models

    attributes do
      property :name, type: String, desc: 'model name'
      property :description, type: String, desc: 'detailed info'
      property :status, type: String, desc: 'IE status'
      property :entity_type, type: String, desc: 'IE entity type'
      property :user_a, type: String, desc: 'value for USER_A metadata'
      property :user_b, type: String, desc: 'value for USER_B metadata'
      property :user_c, type: String, desc: 'value for USER_C metadata'
      property :identifier, type: String, desc: 'value for dc:identifier metadata'
    end

    link :jobs do |opts|
      "#{self.class.self_url(opts)}/#{represented.id}/jobs"
    end

    link :access_right do |opts|
      "#{self.class.self_url(opts)}/#{represented.id}/access_right"
    end

    link :retention_period do |opts|
      "#{self.class.self_url(opts)}/#{represented.id}/retention_period"
    end

    link :manifestations do |opts|
      "#{self.class.self_url(opts)}/#{represented.id}/manifestations"
    end

    # noinspection RubyResolve
    link :workflow do |opts|
      "#{opts[:base_url]}/workflows/#{represented.workflow_id}"
    end

  end
end