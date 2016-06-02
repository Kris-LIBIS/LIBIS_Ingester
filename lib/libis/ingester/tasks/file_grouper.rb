# encoding: utf-8
require 'libis-ingester'

module Libis
  module Ingester

    class FileGrouper < Libis::Ingester::Task

      parameter group_regex: nil,
                description: 'Regular expression for matching against the file names; nothing happens if nil.'
      parameter collection_label: nil,
                description: 'A Ruby expression for the collection path to put the target in.'
      parameter group_label: nil,
                description: 'A Ruby expression for the label of the group; default: nil, meaning no grouping.'
      parameter group_name: nil,
                description: 'A Ruby expression for the name of the group; default: same as group_label.'
      parameter file_label: nil,
                description: 'A Ruby expression for the label of the files; default: file name.'
      parameter file_name: nil,
                description: 'A Ruby expression for the name of the files; default: don\'t change.'
      parameter collection_navigate: true,
                description: 'Allow navigation through the collections.'
      parameter collection_publish: true,
                description: 'Publish the collections.'

      parameter recursive: true

      parameter item_types: [Libis::Ingester::FileItem], frozen: true

      protected

      def process(item)
        grouping = parameter(:group_regex)
        if grouping && item.filename =~ Regexp.new(grouping)
          collections = eval(parameter(:collection_label)).to_s.split('/') rescue []
          target_parent = item.parent
          collections.each do |collection|
            sub_parent = target_parent.get_items.select do |c|
              c.is_a?(Libis::Ingester::Collection) && c.name == collection
            end.first
            unless sub_parent
              sub_parent = Libis::Ingester::Collection.new
              sub_parent.name = collection
              sub_parent.navigate = parameter(:collection_navigate)
              sub_parent.publish = parameter(:collection_publish)
              target_parent.add_item(sub_parent)
              debug 'Created new Collection item: %s', sub_parent, collection
            end
            target_parent = sub_parent
          end
          group = nil
          if parameter(:group_label)
            group_label = eval(parameter(:group_label))
            group_name = parameter(:group_name) ? eval(parameter(:group_name)) : group_label
            group = target_parent.get_items.select { |g| g.name == group_name }.first
            unless group
              group = Libis::Ingester::Division.new
              group.name = group_name
              group.label = group_label
              target_parent.add_item(group)
              debug 'Created new Division item for group: %s', group, group_label
            end
          end
          if parameter(:file_label)
            item.label = eval(parameter(:file_label))
            debug 'Assigning label %s', item, item.label
          end
          if parameter(:file_name)
            file_name = eval(parameter(:file_name))
            debug 'Renaming to %s', item, file_name
            item.name = file_name
          end
          if group
            debug 'Adding to group %s', item, group.name
            item = group.move_item(item)
          end
          item.save!
        end
        self.processing_item = item
      end

      private

      attr_accessor :file_registry

    end

  end
end
