require 'libis-ingester'
require_relative 'base/csv_mapping'

require 'set'
require 'nokogiri'

module Libis
  module Ingester

    class BbNotesCollector < Libis::Ingester::Task

      include Libis::Ingester::CsvMapping

      parameter root_dir: '/',
                description: 'Root directory of the Lotus Notes export.'
      parameter location: '.',
                description: 'Subdirectory to start processing. Should be equal to or subdirectory of root_dir.'
      parameter csv_file: 'export.csv',
                description: 'CSV file with export list.'

      parameter item_types: [Libis::Ingester::Run], frozen: true

      protected

      # Process the input directory on the FTP server for new material
      # @param [Libis::Ingester::Run] item
      def process(item)
        csv = Libis::Tools::Csv.open(parameter(:csv_file), mode: 'rb:windows-1252:UTF-8', required: %w'Pad')
        matchdata = /^#{parameter(:root_dir)}\/?(.*)/.match(parameter(:location))
        raise Libis::WorkflowAbort,
              'Processing directory `%s` is not a subdirectory of the root directory `%s`.' % [
                  parameter(:location),
                  parameter(:root_dir)
              ] unless (matchdata)
        processing_path = matchdata[1]
        ie_count = 0
        csv.each_with_index do |row, line|
          rel_path = row['Pad'].gsub(/^c:\\export\\/, '').gsub(/\\/, '/')
          next unless rel_path =~ /^#{processing_path}\/?/
          next unless check_duplicate_html rel_path, line + 2
          next unless check_file_exist rel_path
          ie_info = process_ie rel_path
          # Create/find directory collection for path
          root = item
          ie_info[:path].split('/').each { |dir|
            child = root.items.find_by(name: dir)
            unless child
              child = Libis::Ingester::Collection.new
              child.extend Libis::Workflow::Base::DirItem
              child.filename = File.join(root.filename rescue parameter(:root_dir), dir)
              child.parent = root
              debug 'Created Collection item `%s`', root, child.name
              child.save!
            end
            root = child
          }
          # Add IE object
          ie = Libis::Ingester::IntellectualEntity.new
          # Embed html file info in the IE
          ie.extend Libis::Workflow::Base::FileItem
          ie.filename = full_path(File.join(ie_info[:path], ie_info[:filename])).to_s
          ie.name = ie_info[:filename]
          ie.label = ie_info[:title]
          ie.parent = root
          debug 'Created IE for `%s`', root, ie.name
          ie.save!
          # Add linked files and images to the IE
          (ie_info.links + ie_info.images).each do |link|
            file = Libis::Ingester::FileItem.new
            file.filename = full_path(File.join(ie_info[:path], link)).to_s
            ie.add_item(file)
            debug 'Created File for `%s`', ie, file.name
            file.save!
          end
          ie_count += 1
          item.status_progress self.namepath, ie_count
        end
        csv.close
      end

      # Process a single HTML file to retrieve the information needed to create an IE for it
      # @param [String] rel_path path to the HTML file relative to the :location parameter
      # @return [Hash] IE information structure: path, name, title, links and images
      def process_ie(rel_path)
        rel_dir, fname = File.split(rel_path)
        f = full_path(rel_path).open
        # noinspection RubyResolve
        html = Nokogiri::HTML(f) { |config| config.strict.nonet.noblanks }
        f.close
        # Title element
        titles = html.css('div table tr td div span strong').map(&:content)
        # Check if title was found
        if titles.empty?
          titles = [File.basename(fname, '.*')]
          warn 'No title element found in HTML file `%s`. Using file name as title.', rel_path
        end
        # File links
        links = html.xpath('//a/@href').map(&:value).map { |link| link2path(link) }.reject { |link| ignore_link(link) }
        # Check if files referenced do exist
        links.reject { |link|
          next false if full_path(File.join(rel_dir, link)).exist?
          warn 'File \'%s\' referenced in HTML file `%s` was not found. Reference will be ignored.', link, rel_path
          true
        }
        # Image links
        images = html.xpath('//img/@src').map(&:value).map { |link| link2path(link) }.reject { |i| ignore_file(i) }
        # Check if images referenced do exist
        images.reject { |link|
          next false if full_path(File.join(rel_dir, link)).exist?
          warn 'Image \'%s\' referenced in HTML file `%s` was not found. Reference will be ignored.', link, rel_path
          true
        }
        # return result
        {
            path: rel_dir,
            filename: fname,
            title: titles.first.gsub(/[\r\n]/, ''),
            links: links,
            images: images,
        }
      end

      # Calculate abslute path using the location parameter as base dir
      # @param [Array[String]] rel_path list of relative paths
      # @return [Pathname] full path name
      def full_path(*rel_path)
        Pathname.new(parameter(:root_dir)).join(*rel_path)
      end

      # Convert link to Pathname
      # @param [String] link
      # @return [Pathname]
      def link2path(link)
        Pathname.new(URI.unescape(link)).cleanpath.to_s
      end

      # Check if link should be ignored
      # @param [Pathname] link link to check
      # @return [Boolean] true if link should be ignored
      def ignore_link(link)
        return true if link =~ /^(mailto:|http:)/
        ignore_file(link)
      end

      # Check if file should be ignored
      # @param [Pathname] rel_name file name to check
      # @return [Boolean] true if file should be ignored
      def ignore_file(rel_name)
        rel_name.to_s =~ /icons\/.*\.gif$/ || rel_name.to_s =~ /\/(TempBody.*|graycol)\.(gif|jpg)$/
      end

      # Checks if a HTML file has been processed
      # Note: this function keeps track of previously processed files in the class instance variable @html_processed and
      # it emits a warning message if it encounters a dubplicate.
      # @param [String] rel_path
      # @param [Integer] line line number in CSV we're currently processing
      # @return [Boolean] true if given file has not been processed before
      def check_duplicate_html(rel_path, line)
        @html_processed ||= Set.new
        if @html_processed.include? rel_path
          warn 'Duplicate HTML file entry found in CSV: `%s` on line %d. Ignoring this duplicate entry.', rel_path, line
          return false
        end
        @html_processed << rel_path
        true
      end

      # Check if a file exists
      # The function emits a warning message if the file does not exist.
      # @param [String] rel_path
      # @return [Boolean] true if file exists
      def check_file_exist(rel_path)
        unless full_path(rel_path).exist?
          warn 'File `%s` not found in export directory. Ignoring this file reference.', rel_path
          return false
        end
        true
      end

    end
  end
end
