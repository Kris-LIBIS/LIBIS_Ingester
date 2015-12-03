# encoding: utf-8
require 'libis-ingester'

module Libis
  module Ingester

    class IeBuilder < Libis::Ingester::Task

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
            # FileItem objects are added to the IE
            item.parent = ie
            debug 'File %s moved to IE %s', item, item.name, ie.name
          when ::Libis::Ingester::Division
            ie = create_ie(item)
            # Division objects are replaced with the IE
            # move the sub items over to the IE
            item.items.each { |i| i.parent = ie }
            # move log info over to the IE
            # noinspection RubyResolve
            item.logs.each { |l| l.logger = ie }
            ie.save!
            debug 'Moved contents of %s from Division to IE.', item, item.name
            @delete_item = true
          else
            # do nothing
        end
      end

      def post_process(item)
        if @delete_item
          debug 'Removing obsolete Division.', item
          item.destroy
          @delete_item = false
        end
      end

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
        ie.parent = (item.parent || item.run)

        # detach the item from it's parent
        item.parent = nil

        # detach the item from the run
        # noinspection RubyResolve
        item.run = nil

        item.save
        ie.save

        # returns the newly created IE
        ie
      end


    end

  end
end
