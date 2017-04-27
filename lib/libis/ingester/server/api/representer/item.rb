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

    # -- Collection

    attributes do
      property :navigate, type: Boolean, desc: 'allow navigation', exec_context: :decorator
      def navigate
        represented.navigate rescue nil
      end

      property :publish, type: Boolean, desc: 'allow publishing via OAI-PMH', exec_context: :decorator
      def publish
      represented.publish rescue nil
      end

      property :description, type: String, desc: 'detailed description', exec_context: :decorator
      def description
        represented.description rescue nil
      end

      nested :identifier, desc: 'external identifier' do
        property :system, type: String, desc: 'system', exec_context: :decorator
        def system
          represented.external_system rescue nil
        end

        property :id, type: String, desc: 'id', exec_context: :decorator
        def id
          represented.external_id rescue nil
        end
      end
    end

    # -- IntellectualEntity

    attributes do
      property :ingest_type, type: String, desc: 'type of ingest', exec_context: :decorator
      def ingest_type
        represented.ingest_type rescue nil
      end

      property :pid, type: String, desc: 'the PID associated to the IE after ingest', exec_context: :decorator
      def pid
        represented.pid rescue nil
      end
    end

    link :retention_period do |opts|
      # noinspection RubyResolve
      "#{opts[:base_url]}/retention_periods/#{represented.retention_period_id}" if represented.respond_to? :retention_period_id
    end

    # -- Representation

    link :representation_info do |opts|
      # noinspection RubyResolve
      "#{opts[:base_url]}/representation_infos/#{represented.representation_info_id}" if represented.respond_to? :representation_info_id
    end

    # -- Division

    # -- DirItem

    # -- FileItem

  end
end

