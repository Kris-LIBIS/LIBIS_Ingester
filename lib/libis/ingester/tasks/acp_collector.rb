require 'libis/ingester'
require 'libis/tools/spreadsheet'

require 'fileutils'
require 'zip'

module Libis
  module Ingester

    class AcpCollector < Libis::Ingester::Task
      taskgroup :collector
      description 'Collector for ACP files preprocessed by Scope'

      help <<-STR.align_left
        This collector needs both an ACP file and a Excel spreadsheet. The 'Rosetta' sheet in the XLS file will be parsed 
        and for each line an IE will be created. The data files will be extracted from the ACP file and the Scope ID in 
        the XLS will be used to retrieve the metadata for the IE.
      STR

      parameter xls_file: nil,
                description: 'XLS file with IE information parsed from the ACP XML file.'

      parameter acp_dir: nil,
                description: 'The folder where the ACP (Alfresco Content Package) export file was extracted.'

      parameter item_types: [Libis::Ingester::Run], frozen: true

      protected

      HEADERS = {
          vp_id: 'VP_DBID',
          scope_id: 'SCOPE_ID',
          file: 'MAIN_FILE',
          name: 'ORIGINAL_FILE_NAME',
          size: 'FILE_SIZE',
          mime: 'FILE_MIMETYPE',
          created: 'FILE_TIMESTAMP_1',
          modified: 'FILE_TIMESTAMP_2',
          checksum_algo: 'FILE_CHECKSUM_ALGORITHM',
          checksum: 'FILE_CHECKSUM_VALUE',
          dc_file: 'DERIVED_FILE',
          dc_size: 'DERIVED_FILE_SIZE',
          dc_mime: 'DERIVED_FILE_MIMETYPE',
          dc_name: 'DERIVED_FILE_ORIGINAL_NAME',
          th_file: 'THUMBNAIL_FILE',
          th_size: 'THUMBNAIL_FILE_SIZE',
          th_mime: 'THUMBNAIL_FILE_MIMETYPE',
          th_date: 'THUMBNAIL_FILE_TIMESTAMP',
      }

      # @param [Libis::Ingester::Run] item
      def process(item)
        unless File.exist?(parameter(:xls_file))
          raise Libis::WorkflowAbort,
                "Excel file '#{parameter(:xls_file)}' cannot not be found."
        end

        unless Dir.exist?(parameter(:acp_dir))
          raise Libis::WorkflowAbort,
                "ACP directory '#{parameter(:acp_dir)}' cannot not be found."
        end

        Libis::Tools::Spreadsheet.foreach("#{parameter(:xls_file)}|Rosetta",
                                          required: HEADERS,
                                          extension: :xls) do |row|
          next if row[HEADERS.first.first] == HEADERS.first.last
          process_row(row)
        end
      end

      private

      def create_file(source, size, target, created, modified, checksum = nil)

        return nil unless source

        file_name = File.join(parameter(:acp_dir), source)
        unless File.exist?(file_name)
          error "Could not find file '#{source}' in the ACP directory"
          return nil
        end

        File.utime(modified.to_time, modified.to_time, file_name)
        file_item = Libis::Ingester::FileItem.new
        file_item.filename = file_name

        unless file_item.properties['size'] == size
          error "File #{name} size does not match metadata info"
          return nil
        end

        unless file_item.properties['checksum_md5'] == checksum
          error "File #{name} checksum does not match metadata info"
          return nil
        end if checksum

        file_item.properties['access_time'] = modified
        file_item.properties['modification_time'] = modified
        file_item.properties['creation_time'] = created
        file_item.properties['original_path'] = target

        file_item.save!
        file_item

      end

      def process_row(row)
        # create IE
        ie = Libis::Ingester::IntellectualEntity.new
        ie.name = row[:name]
        ie.label = row[:name]
        ie.parent = workitem
        ie.properties['scope_id'] = row[:scope_id].to_i
        debug "Created IE for '#{row[:scope_id].to_i}' - '#{row[:name]}'"
        ie.save!

        created = DateTime.iso8601(row[:created])
        modified = DateTime.iso8601(row[:modified])

        if (original = create_file(row[:file], row[:size], row[:name], created, modified, row[:checksum]))
          original.properties['rep_type'] = 'original'
          original.save!
          ie << original
          ie.save!
          debug "Added original file to IE", ie
        end


        if (derived = create_file(row[:dc_file], row[:dc_size], (row[:dc_name] || row[:name]), created, modified))
          derived.properties['rep_type'] = 'derived'
          derived.save!
          ie << derived
          ie.save!
          debug "Added derived file to IE", ie
        end

        fname = "#{File.basename row[:name]}#{File.extname row[:th_file]}"
        if (thumbnail = create_file(row[:th_file], row[:th_size], fname, created, modified))
          thumbnail.properties['rep_type'] = 'thumbnail'
          thumbnail.save!
          ie << thumbnail
          ie.save!
          debug "Added thumbnail file to IE", ie
        end

      end

    end

  end
end
