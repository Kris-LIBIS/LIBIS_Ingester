require 'libis-workflow'
require 'libis-ingester'
require 'naturally'

module Libis
  module Ingester

    class DirCollector < Libis::Ingester::Task

      parameter location: '.',
                description: 'Directory to start scanning in.'

      parameter sort: true, description: 'Sort entries.'

      parameter selection: '',
                description: 'Only select files that match the given regular expression. Ignored if empty.'
      parameter ignore: nil,
                description: 'File pattern (Regexp) of files that should be ignored.'

      parameter recursive: false
      parameter subdirs: 'ignore', constraint: %w[ignore recursive collection complex],
                description: 'How to collect subdirs'

      parameter file_limit: 5000,
                description: 'Maximum number of files to collect. If the number of files found exceeds this limit, the task will fail.'

      parameter item_types: [Libis::Ingester::Run, Libis::Workflow::DirItem], frozen: true

      protected

      def process(item)
        if item.is_a? ::Libis::Ingester::Run
          collect(item, parameter(:location))
        elsif item.is_a? Libis::Workflow::DirItem
          collect(item, item.filepath)
        end
      end

      def collect(item, dir)
        debug 'Collecting files in \'%s\'', dir
        add_files(item, dir, Dir.entries(dir))
        item.save!
      end

      def add_files(item, dir, list)
        reg = parameter(:selection)
        reg = (reg and !reg.empty?) ? Regexp.new(reg) : nil
        ignore = parameter(:ignore) && Regexp.new(parameter(:ignore))
        list = Naturally.sort_by_block(list) { |x| x.gsub('.', '.0.').gsub('_','.') }
        list.each do |file|
          file.strip!
          next if file =~ /^\.{1,2}$/
          path = File.join(dir, file)
          next if reg && File.file?(path) && !((file =~ reg) || (path =~ reg))
          next if ignore and (file =~ ignore || line =~ ignore)
          add(item, path)
        end
      end

      def add(item, file)
        @counter ||= 0
        child = nil
        if File.directory?(file)
          case parameter(:subdirs).to_s.downcase
            when 'recursive'
              collect(item, file)
            when 'collection'
              child = Libis::Ingester::DirCollection.new
              child.filename = file
              debug 'Created Collection item `%s`', child.name
              item.add_item(child)
              collect(child, file)
            when 'complex'
              child = Libis::Ingester::DirDivision.new
              child.filename = file
              debug 'Created Division item `%s`', child.name
              item.add_item(child)
              collect(child, file)
            else
              info "Ignoring subdir #{file}."
          end
        elsif File.file?(file)
          child = Libis::Ingester::FileItem.new
          child.filename = file
          debug 'Created File item `%s`', child.name
          @counter += 1
          item.add_item(child)
        end
        if @counter > parameter(:file_limit)
          fatal_error 'Number of files found exceeds limit (%d). Consider splitting into separate runs or raise limit.',
                item.get_run, parameter(:file_limit)
          raise Libis::WorkflowAbort, 'Number of files exceeds preset limit.'
        end
        return unless child
        child.save!
        item.get_run.status_progress(self.namepath, @counter)
      end

    end
  end
end
