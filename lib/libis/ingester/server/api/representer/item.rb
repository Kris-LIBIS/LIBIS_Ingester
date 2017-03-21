require_relative 'base'

module Libis::Ingester::API::Representer
  class ItemRepresenter < Grape::Roar::Decorator
    include Base

    attributes do
      property :options, type: Hash, desc: 'Hash of item options'
      property :properties, type: Hash, desc: 'set of item properties'
      property :status_log, type: Array, desc: 'list of status updates'
      property :metadata_record, type: String, desc: 'item metadata in Dublin Core format'
    end

    link :access_right do

    end

    link :parent do

    end

    link :items do

    end

    protected

    def job_name

    end
  end
end

