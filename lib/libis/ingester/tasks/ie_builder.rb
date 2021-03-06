# encoding: utf-8
require 'libis-ingester'

module Libis
  module Ingester

    class IeBuilder < Libis::Ingester::Task

      taskgroup :preingester

      parameter recursive: true

      protected

      def pre_process(item)
        # Check if there exists an IE somewhere up the hierarchy
        skip_processing_item if get_ie(item)
      end

      def process(item)

        case item
          when Libis::Ingester::FileItem
            ie = create_ie(item)
            ie.save!
            item = ie.move_item(item)
            debug 'File item %s moved to IE item %s', item, item.name, ie.name
          when ::Libis::Ingester::Division
            ie = create_ie(item)
            # Division objects are replaced with the IE
            # move the sub items over to the IE
            item.get_items.each { |i| ie.move_item(i) }
            debug 'Moved contents of %s from Division item to IE item.', item, item.name
            item.parent = nil
            item.destroy!
            self.processing_item = ie
          else
            # do nothing
        end
      end

      def get_ie(for_item)
        ([for_item] + for_item.ancestors).select do |i|
          i.is_a? ::Libis::Ingester::IntellectualEntity
        end.first rescue nil
      end

      def create_ie(item)
        # Create an the IE for this item
        debug "Creating new IE item for item #{item.name}"
        ie = ::Libis::Ingester::IntellectualEntity.new
        ie.name = item.name
        ie.label = item.label

        # Add IE to item's parent
        item.parent.add_item(ie)

        # returns the newly created IE
        ie
      end


    end

  end
end
