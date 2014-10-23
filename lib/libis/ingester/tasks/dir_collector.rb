# encoding: utf-8

require 'LIBIS_Workflow'
require 'libis/ingester/run'
require 'libis/ingester/file_item'
require 'libis/ingester/collection'
require 'libis/ingester/mets_division'

module LIBIS
  module Ingester

    class DirCollector < ::LIBIS::Workflow::Task

      parameter location: '.',
                description: 'Dir location to scan for files.'
      parameter wildcard: '*',
                description: 'Wildcard expression (glob syntax) for collecting the files and directories.'
      parameter subdirs: 'ignore', default: 'ignore',
                description: 'How to collect subdirs', constraint: %w[ignore recursive collection METS complex]
      parameter selection: '',
                description: 'Only select files that match the given regular expression. Ignored if empty.'

      parameter group_match: nil,
                description: 'Regular expression to match the file path against. Use expression groups if you want to reuse values in the file and group labels. No grouping if nil.'
      parameter group_label: nil,
                description: 'Label of group object to create (ruby expression). First expression group in the group_match expression if nil.'
      parameter group_file: nil,
                description: 'Label of file object in a group (ruby expression). Can refer to regexp groups from "selection". Regular label if nil.'

      def process(item)
        if item.is_a? ::LIBIS::Ingester::Run
          collect(item, options[:location])
        elsif item.is_a? LIBIS::Workflow::DirItem
          collect(item, item.filepath)
        end
      end

      def collect(item, dir)
        glob_string = File.join(dir, options[:wildcard])

        debug 'Scanning for files in \'%s\'', glob_string
        Dir.glob(glob_string).select do |x|
          (File.file?(x) and options[:selection] and !options[:selection].empty?) ? x =~ Regexp.new(options[:selection]) : true
        end.sort.each do |file|
          next if file =~ /\/\.{1,2}$/
          add(item, file)
        end
      end

      def add(item, file)

        child = nil
        if File.directory?(file)
          case options[:subdirs].to_s.downcase
            when 'recursive'
              collect(item, file)
            when 'collection'
              child = LIBIS::Ingester::Collection.new
              child.extend LIBIS::Workflow::DirItem
              child.filename = file
              collect(child, file)
            when 'mets', 'complex'
              child = LIBIS::Ingester::MetsDivision.new
              child.extend LIBIS::Workflow::DirItem
              child.filename = file
              collect(child, file)
            else
              info "Ignoring subdir #{file}."
          end
        elsif File.file?(file)
          child = LIBIS::Ingester::FileItem.new
          child.filename = file
          grouping = options[:group_match]
          if grouping && file =~ Regexp.new(grouping)
            group_label = eval(options[:group_label] || '$1')
            group = item.items.select { |i| i.name == group_label }.first
            unless group
              group = LIBIS::Ingester::MetsDivision.new
              group.name = group_label
              item << group
            end
            item = group
            child.name = eval(options[:group_file]) if options[:group_file]
          end
        end
        return unless child
        child.filename = file
        item << child
        item.save
      end

    end
  end
end
