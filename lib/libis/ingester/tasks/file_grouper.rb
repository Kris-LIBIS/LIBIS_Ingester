# encoding: utf-8
require 'libis-ingester'

module Libis
  module Ingester

    class FileGrouper < Libis::Ingester::Task

      parameter group_regex: nil,
                description: 'Regular expression for matching against the file names; no grouping if nil.'
      parameter group_label: '$1',
                description: 'A Ruby expression for the label (name) of the group; default: $1.'
      parameter file_label: nil,
                description: 'A Ruby expression for the label (name) of the files; default: file name.'

      parameter recursive: true

      def process(item)
        return unless item.is_a? ::Libis::Ingester::FileItem
        debug 'Processing item: %s', item.name
        uplevel = item.uplevel
        # noinspection RubyResolve
        grouping = parameter(:group_regex)
        if grouping && item.filename =~ Regexp.new(grouping)
          # noinspection RubyResolve
          group_label = eval(parameter(:group_label))
          group = uplevel.items.select { |g| g.name == group_label }.first
          unless group
            group = Libis::Ingester::Division.new
            group.name = group_label
            group.parent = item.parent if item.parent
            # noinspection RubyResolve
            group.run = item.run if item.run
            group.save
            debug 'Created new group: %s', group_label
          end
          new_name = parameter(:file_label) ? eval(parameter(:file_label)) : item.name
          debug 'Adding to group %s as %s', group.name, new_name
          item.name = new_name
          item.parent = group
          # noinspection RubyResolve
          item.run = nil
        end
      end

    end

  end
end
