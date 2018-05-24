require 'libis-workflow'
require 'libis-ingester'
require 'naturally'

module Libis
  module Ingester

    class DirCollector < Libis::Ingester::Task

      taskgroup :collector

      description 'Parse a directory tree and collect all files and folders in it.'

      help <<-STR.align_left
        The directory tree at parameter 'location' will be parsed and ingest objects will be created for files and
        folders found. The behaviour can be extensively configured with the parameters:

        All files will be used, unless the 'selection' parameter is filled in. It should contain a regular expression
        and only files that match the expression will be used for FileItem object creation. Files not matching will be
        silently ignored. Similarly, the optional 'ignore' parameter can contain a regular expression that causes the 
        files that match to be ignored and only files that do not match will pass the test. Both the file name and the
        file path are tested against the regular expressions. Note that only files found are checked against the regular
        expression of the 'selection' parameter, while also the subdirectories found will be checked against the regular
        expression of the 'ignore' parameter, thus allowing to completely ignore subfolders and its contents in the
        collector.
        
        The parameter 'subdirs' decides how subdirectories are processed. The following values are possible:
        - 'ignore': any subdirectory will be ignored and the task will only process files in the top directory
        - 'recursive': the task will not create an ingest object for the subdirectories, but will parse it contents and
          further process the files and folders in it. This has the same effect as if all files would reside in the same
          top-level directory
        - 'collection': for each subdirectory, a Collection is created and FileItem object representing files in the 
          subdirectory will be part of the Collection. The folder structure will be ingested in Rosetta as a collection
          tree
        - 'complex': for each subdirectory encountered a Division object will be created. During the collection phase
          the folder structure will be captured as a tree of Division objects. In the preingest phase the top-level
          Division object will be converted in an IE by the IeBuilder task. The net effect is that for each top-level 
          subdirectory an IE will be created and the directory tree below that directory will be captured as a 'complex
          object' in a structmap.
        - 'leaf': as 'complex' above, but only for the leaf directories - a.k.a. directories that do not contain
          any sub-directories - a Division object is created. All files in a leaf directory will be added to the division
          but a file in any other directory will not be added to a division and will result in an individual IE.

        For performance reasons, the collector limits the number of files it can collect. By default this is set to
        5000 as the ingest will start to get exponentially slower with files > 5000. This can be overwritten if 
        required with the 'file_limit' parameter.

        By default, this collector will perform a natural sort (https://en.wikipedia.org/wiki/Natural_sort_order) on 
        the directory entries found. This behaviour can be turned off by setting the 'sort' parameter to false. Note 
        that in that case the entries will be listed in the order as provided by the underlying file system, which may
        be hard to control. If you want the objects ingested in a specific order, consider the DirListCollector task
        instead.
      STR

      parameter location: '.',
                description: 'Directory to start scanning in.'

      parameter sort: true, description: 'Sort entries.'

      parameter selection: '',
                description: 'Only select files that match the given regular expression. Ignored if empty.'

      parameter ignore: nil,
                description: 'File pattern (Regexp) of files that should be ignored.'

      parameter subdirs: 'ignore', constraint: %w[ignore recursive collection complex leaf],
                description: 'How to collect subdirs'

      parameter file_limit: 5000,
                description: 'Maximum number of files to collect. If the number of files found exceeds this limit, the task will fail.'

      parameter recursive: false

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
        list = Naturally.sort_by_block(list) {|x| x.gsub('.', '.0.').gsub('_', '.')} if parameter(:sort)
        list.each do |file|
          file.strip!
          next if file =~ /^\.{1,2}$/
          path = File.join(dir, file)
          if reg && File.file?(path) && !((file =~ reg) || (path =~ reg))
            next if ignore and (file =~ ignore || path =~ ignore)
            warn "Found file '#{File.basename(path)}' in folder '#{File.dirname(path)}' that did not match the selection regex.", item
            next
          end
          unless File.exists?(path)
            warn "File '#{path}' not found."
            next
          end
          unless File.readable?(path)
            warn "Skipping file '#{path}' since it cannot be read."
            next
          end
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
          when 'leaf'
            if is_leaf_dir?(file)
              child = Libis::Ingester::DirDivision.new
              child.filename = file
              debug 'Created Division item `%s`', child.name
              item.add_item(child)
              collect(child, file)
            end
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

      def is_leaf_dir?(dir)
        Dir.entries(dir).reject do |x|
          %w'. ..'.include?(x) || File.file?(File.join(dir, x))
        end.empty?
      end

    end
  end
end
