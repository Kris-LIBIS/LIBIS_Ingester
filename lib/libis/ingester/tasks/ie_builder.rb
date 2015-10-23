# encoding: utf-8
require 'libis-ingester'

module Libis
  module Ingester

    class IeBuilder < Libis::Ingester::Task

      parameter ingest_model: nil,
                description: 'Ingest model name for the configuration of the IE building process.'

      parameter recursive: true

      def pre_process(_)
        ingest_model_name = parameter(:ingest_model) || 'default'
        @ingest_model ||= ::Libis::Ingester::IngestModel.find_by(name: ingest_model_name)
        raise WorkflowError, 'Ingest model %s not found.' % ingest_model_name unless @ingest_model
      end

      def process(item)

        # Check if there exists an IE somewhere up the hierarchy
        return if get_ie(item)

        case item
          when Libis::Ingester::FileItem
            ie = create_ie(item)
            # FileItem objects are added to the IE
            ie << item
          when ::Libis::Ingester::Division
            ie = create_ie(item)
            # Division objects are replaced with the IE
            item.items.each { |i| ie << i }
            item.destroy
            return ie
          else
            # do nothing
        end

      end

      protected

      def get_ie(for_item)
        for_item.ancestors.select do |i|
          i.is_a? ::Libis::Ingester::IntellectualEntity
        end.first rescue nil
      end

      def create_ie(item)
        # Create an the IE for this item
        debug "Creating new IE for item #{item.name}"
        ie = ::Libis::Ingester::IntellectualEntity.new
        ie.name = item.name

        # Substitute the IE for the item
        (item.parent || item.run) << ie

        # detach the item from it's parent
        item.parent = nil

        # detach the item from the run
        # noinspection RubyResolve
        item.run = nil

        # returns the newly created IE
        ie
      end


    end

  end
end
