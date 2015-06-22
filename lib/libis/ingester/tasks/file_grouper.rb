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
        parent = item.parent
        # noinspection RubyResolve
        grouping = parameter(:group_regex)
        if grouping && item.filename =~ Regexp.new(grouping)
          # noinspection RubyResolve
          group_label = eval(parameter(:group_label))
          group = parent.items.select { |g| g.name == group_label }.first
          unless group
            group = Libis::Ingester::Division.new
            group.name = group_label
            group.parent = parent
            group.save
            debug 'Created new group: %s', group_label
          end
          item.parent = group
          # noinspection RubyResolve
          item.name = eval(parameter(:file_label)) if parameter(:file_label)
          debug 'File name: %s', item.name
        end
      end

    end

  end
end
