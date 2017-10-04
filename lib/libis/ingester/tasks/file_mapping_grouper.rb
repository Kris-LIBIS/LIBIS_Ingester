require 'libis-ingester'

require_relative 'base/mapping'
module Libis
  module Ingester

    class FileMappiongGrouper < Libis::Ingester::Task
      include Libis::Ingester::Base::Mapping

      taskgroup :preingester

      description 'Groups files into object based on mapping file.'

      help <<-STR.align_left
        Files can be grouped together into a single IE with this task by using a mapping file (e.g. CSV).

        The mapping file should contain the file name, the name of the IE it belongs to. Optionally it can also have
        a label for the file and a collection name (or names as a path).  

        The value of the parameters 'collection_navigate' and 'collection_publish' set the respective properties of
        any newly created collections.
      STR

      parameter file_label_field: nil,
                description: 'The name of the column in the mapping table that contains the label of the file. ' +
                    'Optional. If omitted, the file label will not be set and defaults to the file name.'
      parameter group_field: nil,
                description: 'The name of the column in the mapping table that contains the name of the IE. ' +
                    'Optional. If omitted, there files will not be grouped into IEs.'
      parameter collection_field: nil,
                description: 'The name of the column in the mapping table that contains the name of the collection ' +
                    'IE should be part of. Optional. If omitted, the IE will not be part of a collection.'
      parameter collection_navigate: true,
                description: 'Allow navigation through the collections.'
      parameter collection_publish: true,
                description: 'Publish the collections.'

      parameter recursive: true
      parameter item_types: [Libis::Ingester::FileItem], frozen: true

      def apply_options(opts)
        super(opts)
        required = Set.new(parameter(:required_fields))
        required << parameter(:group_field)
        required << parameter(:file_label_field) if parameter(:file_label_field)
        required << parameter(:collection_field) if parameter(:file_label_field)
        set = Set.new(parameter(:mapping_headers))
        set += required
        required = [parameter(:mapping_key)] + required.to_a
        parameter(:mapping_headers, set.to_a)
        parameter(:required_fields, required)
      end

      protected

      def process(item)
        target_parent = item.parent
        if (collection_field = parameter(:collection_field))
          if (collections = lookup(item.filename, collection_field))
            collections.to_s.split('/') rescue [].each do |collection|
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
          end
        end
        if (group_field = parameter(:group_field))
          if (group_name = lookup(item.filename, group_field))
            group = target_parent.get_items.select {|g| g.name == group_name && g.is_a?(Libis::Ingester::Division)}.first
            unless group
              group = Libis::Ingester::Division.new
              group.name = group_name
              group.label = group_name
              target_parent.add_item(group)
              debug 'Created new Division item for group: %s', group, group_name
            end
            target_parent = group
          end
        end
        if (file_label_field = parameter(:file_label_field))
          if (file_label = lookup(item.filename, file_label_field))
            item.label = file_label
            debug 'Assigning label %s', item, item.label
          end
        end
        unless target_parent == item.parent
          debug 'Moving item to %s', item, target_parent.name
          item = target_parent.move_item(item)
        end
        item.save!
        self.processing_item = item
      end

    end

  end
end
