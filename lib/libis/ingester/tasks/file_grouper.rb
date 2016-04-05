# encoding: utf-8
require 'libis-ingester'

module Libis
  module Ingester

    class FileGrouper < Libis::Ingester::Task

      parameter group_regex: nil,
                description: 'Regular expression for matching against the file names; no grouping if nil.'
      parameter collection_label: nil,
                description: 'A Ruby expression for the collection path to put the target in.'
      parameter group_label: nil,
                description: 'A Ruby expression for the label of the group; default: nil, meaning no grouping.'
      parameter file_label: nil,
                description: 'A Ruby expression for the label of the files; default: file name.'
      parameter group_name: nil,
                description: 'A Ruby expression for the name of the group; default: same as group_label.'
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
          target_parent = item.uplevel
          collections.each do |collection|
            sub_parent = target_parent.items.select do |c|
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
            group = target_parent.items.select { |g| g.name == group_name }.first
            unless group
              group = Libis::Ingester::Division.new
              group.name = group_name
              group.label = group_label
              target_parent.add_item(group)
              debug 'Created new Division item for group: %s', group, group_label
            end
          end
          file_label = parameter(:file_label) ? eval(parameter(:file_label)) : item.name
          item.name = eval(parameter(:file_name)) if parameter(:file_name)
          item.label = file_label
          item.properties['group_id'] = register_file(item.name)
          if group
            debug 'Adding to group %s as %s', item, group.name, file_label
            group.add_item(item)
          end
        end
      end

      private

      attr_accessor :file_registry

      def register_file(name)
        @file_registry ||= {}
        return @file_registry[name] if @file_registry.has_key?(name)
        @file_registry[name] = @file_registry.count + 1
      end

    end

  end
end
