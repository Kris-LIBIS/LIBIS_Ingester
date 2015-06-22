# encoding: utf-8
require 'libis-ingester'

module Libis
  module Ingester

    class IeBuilder < Libis::Ingester::Task

      parameter ingest_model: nil,
                description: 'Ingest model name for the configuration of the IE building process.'

      parameter recursive: true

      def pre_process(item)
        ingest_model_name = parameter(:ingest_model) || 'default'
        @ingest_model ||= ::Libis::Ingester::IngestModel.find_by(name: ingest_model_name)
        raise WorkflowError, 'Ingest model %s not found.' % ingest_model_name unless @ingest_model
      end

      def process(item)
        item_list = nil
        destroy_self = false
        case item
          when ::Libis::Ingester::Division
            destroy_self = true
            item_list = item.items
          when ::Libis::Ingester::FileItem
            #nothing
          else
            return
        end
        # Check if there exists an IE somewhere up the hierarchy
        ie = get_ie(item)
        unless ie
          ie = create_ie(item, item.parent || item.run, item_list)
          if destroy_self
            item.parent = nil
            # noinspection RubyResolve
            item.run = nil
            item.destroy
            # required for the task to be able to continue it's processing
            self.workitem = ie
          end
        end

      end

      protected

      def get_ie(for_item)
        for_item.ancestors.select do |i|
          i.is_a? ::Libis::Ingester::IntellectualEntity
        end.first
      end

      def create_ie(item, parent, children = nil)
        ie = ::Libis::Ingester::IntellectualEntity.new
        ie.name = item.name
        parent << ie
        rep = ::Libis::Ingester::Representation.new
        rep.name = 'Archiefkopie'
        rep.representation_info = ::Libis::Ingester::RepresentationInfo.find_by(name: 'ARCHIVE')
        # noinspection RubyResolve
        children.nil? ? (item.parent = rep; item.run = nil) : children.each { |c| c.parent = rep }
        rep.parent = ie
        ie.save
        ie
      end

      def get_archive_rep(ie)
        ie.representations.select do |rep|
          # noinspection RubyResolve
          rep.representation_info.preservation_type == 'PRESERVATION_MASTER'
        end.first
      end

    end

  end
end
