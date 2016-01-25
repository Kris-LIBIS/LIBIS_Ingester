# encoding: utf-8
require 'libis-ingester'

module Libis
  module Ingester

    class FileGrouper < Libis::Ingester::Task

      parameter group_regex: nil,
                description: 'Regular expression for matching against the file names; no grouping if nil.'
      parameter collection_label: nil,
                description: 'A Ruby expression for the collection path to put the target in.'
      parameter group_label: '$1',
                description: 'A Ruby expression for the label (name) of the group; default: $1.'
      parameter file_label: nil,
                description: 'A Ruby expression for the label (name) of the files; default: file name.'
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
          group_label = eval(parameter(:group_label))
          group = target_parent.items.select { |g| g.name == group_label }.first
          unless group
            group = Libis::Ingester::Division.new
            group.name = group_label
            target_parent.add_item(group)
            debug 'Created new Division item for group: %s', group, group_label
          end
          new_name = parameter(:file_label) ? eval(parameter(:file_label)) : item.name
          debug 'Adding to group %s as %s', item, group.name, new_name
          item.name = new_name
          item.properties[:group_id] = register_file(item.name)
          group.add_item(item)
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
