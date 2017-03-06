require 'libis-tools'
require 'libis-workflow'
require 'libis-ingester'

require 'csv'
require 'libis/tools/extend/string'

module Libis
  module Ingester

    class ThesisToledoCollector < Libis::Ingester::Task

      taskgroup :collector

      parameter location: nil,
                description: 'Directory path where the values.csv files are located'

      parameter unzip_dir: nil,
                description: 'Directory path where the thesis files have been unzipped'

      parameter value_files: %w(values.csv.pub values.sup.pub),
                description: 'List of names of CSV files to process'

      parameter access_rights: %w(AR_PUBLIC AR_PRIVATE),
                description: 'List of access right names, one for each CSV file passed'

      parameter entity_type: 'ETD_KUL',
                description: 'Entity type for the IEs'

      parameter user_c: 'ETD',
                description: 'Value for the user_c field'

      parameter item_types: [Libis::Ingester::Run], frozen: true
      parameter recursive: false, frozen: true

      protected

      # Process the input directory on the FTP server for new material
      # @param [Libis::Ingester::Run] item
      def process(item)
        @work_dir = item.work_dir

        # sanity checks
        location = parameter(:location)
        unless Dir.exists?(location)
          error 'Location path %s does not exist.', location
          raise Libis::WorkflowError, 'Directory not found'
        end

        parameter(:value_files).each_with_index do |csv_file, index|
          process_csv(File.join(location, csv_file), parameter(:access_rights)[index])
        end

      end

      private
      # @param [String] csv_file path to the CSV file
      # @param [String] ar Access Right name to use
      def process_csv(csv_file, ar)
        files_csv = CSV.open(csv_file, headers: true, skip_blanks: true)
        file_list = files_csv.each

        ie_csv = CSV.open(csv_file, headers: true, skip_blanks: true)
        ie_list = ie_csv.each

        while (row = ie_list.find { |r| r['entity type'] == 'COMPLEX' })
          catch :error do
            vpid = row['vpid']
            files = file_list.rewind.select { |r| r['relation'] == vpid }
            files.each do |f|
              f[:path] = File.join(parameter(:unzip_dir), f['file name old'])
              unless File.exists?(f[:path])
                error 'File %s could not be found. Thesis %s skipped.', f[:path], row['label']
                throw :error
              end
              f[:order] = 0
              name = f['file name'].downcase
              if File.extname(name) == '.pdf'
                f[:order] += 1
                f[:order] += name.scan(/eindwerk|bachelorproef|masterproef/).count
              end
            end
            files.sort! { |f1, f2| f2[:order] <=> f1[:order] }
            ie_item = Libis::Ingester::IntellectualEntity.new
            ie_item.name = row['label'].gsub(/[^0-9A-Za-z._]/, '_')
            ie_item.label = row['label']
            ie_item.properties['entity_type'] = parameter(:entity_type)
            ie_item.properties['access_right'] = ar
            ie_item.properties['vpid'] = vpid
            ie_item.properties['user_a'] = 'Ingest from Toledo'
            ie_item.properties['user_b'] = row['embargo opmerking']
            ie_item.properties['user_c'] = parameter(:user_c)

            # Build Dublin Core record from the rest of the XML
            # noinspection RubyResolve
            ie_item.metadata_record_attributes = {
                format: 'DC',
                data: create_metadata(row).to_xml
            }
            files.each do |f|
              file_item = Libis::Ingester::FileItem.new
              file_item.filename = f[:path]
              file_item.name = f['file name']
              file_item.label = f['label']
              ie_item << file_item
            end
            self.workitem << ie_item
            ie_item.save!
          end
        end

        files_csv.close
        ie_csv.close
      end

      # @param [CSV::Row] row
      # noinspection RubyResolve
      def create_metadata(row)
        xml = ::Libis::Tools::Metadata::DublinCoreRecord.new
        xml.identifier = row['<dc:identifier>'].strip
        xml.title = row['<dc:title>'].gsub(/""/, '"').strip

        row.headers.select { |h| h =~ /<dc:creator>/ }.each do |i|
          value = row[i]
          next if value.blank?
          add_node(xml, :creator!) { value }
        end

        xml.description = row['<dc:description>']
        xml.publisher = row['<dc:publisher>']

        row.headers.select { |h| h =~ /<dc:contributor>/ }.each do |i|
          value = row[i]
          next if value.blank?
          add_node(xml, :contributor!) { value }
        end

        xml.source = row['<dc:source>']
        xml.rights = row['<dc:rights>']
        xml.date = row['date']

        row.headers.select { |h| h =~ /<dc:type>/ }.each do |i|
          value = row[i]
          next if value.blank?
          add_node(xml, :type!) { value }
        end

        xml.abstract = row['abstract']

        xml
      end

      def add_node(xml, node_name)
        value = yield
        node_name = "#{node_name.to_s}=" unless node_name.to_s[-1] == '!'
        xml.send(node_name, value)
      rescue
        warn "Could not create metadata field: #{node_name} for #{xml.title.text}"
      end

    end
  end
end
