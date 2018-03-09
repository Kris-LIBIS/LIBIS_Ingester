require 'libis-ingester'
require 'libis/tools/metadata/dublin_core_record'
require_relative 'base/csv_mapping'

require 'date'
require 'set'
require 'nokogiri'

module Libis
  module Ingester

    class BbNotesCollector < Libis::Ingester::Task

      taskgroup :collector

      description 'Special collector for ingesting Lotus Notes export of Boerenbond.'

      help <<-STR.align_left
        This collector requires a CSV file with the export of the Lotus Notes documents. The CSV file is expected to be
        in windows-1253 encoding and requires at least one column with heading 'Pad'.

        For each entry in the CSV file, the 'Pad' column is read, the starting 'c:\export\' text stripped from it and
        converted to Unix style path. Each such entry must be the relative path from the 'root_dir' and refer to a HTML
        file that is the export of a Lotus Notes document. Duplicate entries and entries to non-existing file are
        skipped, but reported with warning messages.

        For each HTML file, a collection tree is created for the relative path from the 'root_dir' and the HTML file is
        parsed for information:
        - the base file name is used as title.
        - all file ('//a/@href') and image ('//img/@src') links are searched and checked for existance. 'mailto' and 
          'http' links and a number of well-know artifacts files are skipped. Other missing links are reported with
          warning messages. If files are referenced that have previously been referenced (even by other HTML files) are
          reported with warning messages and ignored.

        The value of the parameters 'collection_navigate' and 'collection_publish' set the respective properties of
        the newly created collections.

        Finally, for each HTML file a new IE is created and the HTML and all referenced files are added to it.

        This collector may throw a lot of warning messages as many things go wrong in the Lotus Notes exports. It has
        been decided to continue the ingest nevertheless and try to ingest as many objects as possible. The warning
        messages should be reported to the producers of the data after successful ingest.
      STR

      include Libis::Ingester::CsvMapping

      parameter root_dir: '/',
                description: 'Root directory of the Lotus Notes export.'
      parameter csv_file: 'VeldenExportCSV.csv',
                description: 'CSV file with export list.'
      parameter collection_navigate: false,
                description: 'Allow navigation through the collections.'
      parameter collection_publish: false,
                description: 'Publish the collections.'

      parameter item_types: [Libis::Ingester::Run], frozen: true

      protected

      # Process the input directory on the FTP server for new material
      # @param [Libis::Ingester::Run] item
      def process(item)
        unless File.exists?(parameter(:csv_file))
          csv_path = File.join(parameter(:root_dir), parameter(:csv_file))
          if File.exists?(csv_path)
            parameter(:csv_file, csv_path)
          else
            raise Libis::WorkflowAbort,
                  "CSV file '#{parameter(:csv_file)}' cannot not be found. It should be absolute or relative to 'root_dir'.",
          end
        end
        # csv = Libis::Tools::Csv.open(parameter(:csv_file), mode: 'rb:windows-1252:UTF-8', required: %w'Pad')
        csv = Libis::Tools::Csv.open(parameter(:csv_file), mode: 'rb:windows-1252:UTF-8', colsep: ';',
                                     required: %w'Pad TitelTX DocumentsvormTX DocumentdatumDT DossiersTX AuteurTX')
        unless parameter(:root_dir) =~ /\/documenten\/?$/
          parameter(:root_dir, File.join(parameter(:root_dir), 'documenten'))
        end
        ie_count = 0
        csv.each_with_index do |row, line|
          rel_path = row['Pad'].gsub(/^c:\\export\\documenten\\/, '').gsub(/\\/, '/')
          title = row['TitelTX']
          doctype = row['DocumentsvormTX']
          docdate = row['DocumentdatumDT']
          docdate = (DateTime.strptime(docdate, "%d_%m_%Y %H_%M_%S") rescue Date.strptime(docdate, "%d_%m_%Y") rescue nil)
          docdossier = row['DossiersTX']
          docauthor = row['AuteurTX']
          next unless check_duplicate_html rel_path, line + 2
          next unless check_file_exist rel_path
          ie_info = process_ie rel_path, title
          next unless ie_info
          # Create/find directory collection for path
          root = item
          root_dir = parameter(:root_dir)
          ie_info[:path].split('/').each {|dir|
            child = root.items.find_by('properties.name' => dir)
            dir_path = File.join(root_dir, dir)
            unless child
              child = Libis::Ingester::Collection.new
              child.filename = dir_path
              child.parent = root
              child.navigate = parameter(:collection_navigate)
              child.publish = parameter(:collection_publish)
              debug 'Created Collection item `%s`', root, child.name
              child.save!
            end
            root = child
            root_dir = dir_path
          }
          # Add IE object
          ie = Libis::Ingester::IntellectualEntity.new
          ie.name = ie_info[:filename]
          ie.label = ie_info[:title]
          ie.parent = root
          debug 'Created IE for `%s`', root, ie.name
          ie.save!

          # create DC metadata
          dc = Libis::Tools::Metadata::DublinCoreRecord.new
          dc.title = ie_info[:title]
          dc.type = doctype unless doctype.blank?
          dc.subject = docdossier unless docdossier.blank?
          # noinspection RubyResolve
          dc.created = docdate if docdate
          # noinspection RubyResolve
          dc.creator = docauthor unless docauthor.blank?

          # Add the metaddata to the IE
          metadata = Libis::Ingester::MetadataRecord.new
          metadata.format = 'DC'
          metadata.data = dc.to_xml
          ie.metadata_record = metadata
          ie.save!

          # Add HTML file to the IE
          file = Libis::Ingester::FileItem.new
          file.filename = full_path(File.join(ie_info[:path], ie_info[:filename])).to_s
          ie.add_item(file)
          debug 'Created File for `%s`', ie, file.filename
          file.save!
          # Add linked files and images to the IE
          ie_info[:links].each do |link|
            file = Libis::Ingester::FileItem.new
            file.filename = full_path(File.join(ie_info[:path], link)).to_s
            ie.add_item(file)
            debug 'Created File for `%s`', ie, file.filename
            file.save!
          end
          ie.save!
          ie_count += 1
          item.status_progress self.namepath, ie_count
        end
        csv.close
      end

      # Process a single HTML file to retrieve the information needed to create an IE for it
      # @param [String] rel_path path to the HTML file relative to the :location parameter
      # @return [Hash] IE information structure: path, name, title, links and images
      def process_ie(rel_path, title)
        rel_dir, fname = File.split(rel_path)
        title ||= File.basename(fname, '.*')
        f = File.open(full_path(rel_path), 'r:UTF-8')
        # noinspection RubyResolve
        html = Nokogiri::HTML(f) {|config| config.strict.nonet.noblanks}
        f.close
        # File links
        links = html.xpath('//a/@href').map(&:value).map {|link| link2path(link)}.reject {|link| ignore_link(link)}
        # Check if files referenced do exist
        links.reject! {|link|
          next false if full_path(File.join(rel_dir, link)).exist?
          warn 'File \'%s\' referenced in HTML file `%s` was not found. Reference will be ignored.', link, rel_path
          true
        }
        # Image links
        images = html.xpath('//img/@src').map(&:value).map {|link| link2path(link)}.reject {|i| ignore_file(i)}
        # Check if images referenced do exist
        images.reject! {|link|
          next false if full_path(File.join(rel_dir, link)).exist?
          warn 'Image \'%s\' referenced in HTML file `%s` was not found. Reference will be ignored.', link, rel_path
          true
        }
        # Remove duplicate links
        link_set = links.to_set + images.to_set
        unless link_set.count == links.count + images.count
          warn 'HTML file `%s` contains duplicate file references. Duplicates are ignored.', rel_path
        end
        # return result
        {
            path: rel_dir,
            filename: fname,
            title: title.strip,
            links: link_set,
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
