# encoding: utf-8

require 'libis-workflow'
require 'libis-ingester'

module Libis
  module Ingester

    class DirCollector < ::Libis::Ingester::Task

      parameter location: '.',
                description: 'Dir location to scan for files.'
      parameter wildcard: '*',
                description: 'Wildcard expression (glob syntax) for collecting the files and directories.'
      parameter subdirs: 'ignore', constraint: %w[ignore recursive collection complex],
                description: 'How to collect subdirs'
      parameter selection: '',
                description: 'Only select files that match the given regular expression. Ignored if empty.'
      parameter ignore: nil,
                description: 'File pattern (Regexp) of files that should be ignored.'

      parameter recursive: false

      def process(item)
        if item.is_a? ::Libis::Ingester::Run
          collect(item, parameter(:location))
        elsif item.is_a? Libis::Workflow::DirItem
          collect(item, item.filepath)
        end
      end

      def collect(item, dir)
        glob_string = File.join(dir, parameter(:wildcard))

        debug 'Collecting files in \'%s\'', glob_string
        Dir.glob(glob_string).select do |x|
          (File.file?(x) and parameter(:selection) and !parameter(:selection).empty?) ? x =~ Regexp.new(parameter(:selection)) : true
        end.sort.each do |file|
          next if file =~ /\/\.{1,2}$/
          next if parameter(:ignore) and file =~ Regexp.new(parameter(:ignore))
          add(item, file)
        end
      end

      def add(item, file)

        child = nil
        if File.directory?(file)
          case parameter(:subdirs).to_s.downcase
            when 'recursive'
              collect(item, file)
            when 'collection'
              child = Libis::Ingester::Collection.new
              child.extend Libis::Workflow::DirItem
              child.filename = file
              collect(child, file)
            when 'complex'
              child = Libis::Ingester::Division.new
              child.extend Libis::Workflow::DirItem
              child.filename = file
              collect(child, file)
            else
              info "Ignoring subdir #{file}."
          end
        elsif File.file?(file)
          child = Libis::Ingester::FileItem.new
          child.filename = file
        end
        return unless child
        child.filename = file
        item << child
        item.save
      end

    end
  end
end
