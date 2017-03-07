require 'libis-ingester'

module Libis
  module Ingester

    class FileGrouper < Libis::Ingester::Task

      taskgroup :preingester

      description 'Groups files into object based on file name.'

      help <<-STR.align_left
        Files that have part of their filename in common can be grouped into a single IE with this task.

        First of all each file is matched against an expression defined in the 'group_regex' parameter. This regex
        should define groups that will be used to extract common and unique pieces of the file names. Based on the
        result of the regex matching, collections and IEs can be generated and file name and labels can be altered.

        If the 'collection_label' parameter is filled in, the value will be evaluated and the resulting value will
        be the name of a newly created Collection object. If no value is present, no Collection will be created.

        The value of the parameters 'collection_navigate' and 'collection_publish' set the respective properties of
        the newly created collections.

        The 'group_label' parameter defines the Ruby expression that will be evaluated to retrieve the name of the
        group (IE) that will be created later. It the value is not present, no grouping of files into IEs will be
        performed. Optionally a different expression for the group name can be added in 'group_name'.

        With the 'file_label' and 'file_name' parameters, expressions can be defined that will change the name and
        label of the files.
      STR

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
          if parameter(:group_label) || parameter(:group_name)
            group_name = eval(parameter(:group_name)) if parameter(:group_name)
            group_label = eval(parameter(:group_label)) if parameter(:group_label)
            # noinspection RubyScope
            group_name ||= group_label
            group_label ||= group_name
            group = target_parent.get_items.select { |g| g.name == group_name && g.is_a?(Libis::Ingester::Division) }.first
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
          elsif target_parent != item.parent
            debug 'Adding to collection %s', item, target_parent.name
            item = target_parent.move_item(item)
          end
          item.save!
        end
        self.processing_item = item
      end

    end

  end
end
