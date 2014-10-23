# encoding: utf-8

require 'LIBIS_Workflow'
require 'LIBIS_Tools'
require 'LIBIS_Ingester'

require 'fileutils'

module LIBIS
  module Ingester

    class DavIngestPreparer < ::LIBIS::Workflow::Task
      parameter ingest_dir: '/nas/vol04/dav_deposit_area',
                description: 'Directory where the ingest files are to be created.'
      parameter ingest_type: 'METS',
                description: 'Collect directories into METS structure or Collections',
                constraint: %w[Collection METS]


      def process(item)
        check_item_type ::LIBIS::Ingester::Run, item

        @dirname = options[:ingest_dir]

        raise RuntimeError, 'No location given.' unless @dirname

        @dirname = File.join(dirname, item.name)

        debug "Preparing ingest in #{@dirname}."

        item.items.map { |i| process_dossier(i) }

      end

      def process_dossier(item)

        check_item_type LIBIS::Ingester::DavDossier

        @mets = LIBIS::Tools::MetsFile.new

        dc_record = LIBIS::Tools::DCRecord.new do |xml|
          xml[:dc].title = item.name
        end
        dc_record.add('dc:identifier', item.properties[:rmt_info][:folder][:referenceCode]) rescue nil
        dc_record.add('dc:date', DateTime.parse(item.properties[:rmt_info][:transfer][:transferredOn])) rescue nil

        @mets.dc_record = dc_record.root.to_xml

        rep = @mets.representation(
            label: item.name,
            preservation_type: 'PRESERVATION_MASTER',
            usage_type: 'VIEW',
        )

        div = @mets.div label: item.name
        @mets.map(rep, div)

        process_children(item, rep, div)
      end

      def process_children(item, rep, div)
        item.items.each do |child|
          case child
            when LIBIS::Ingester::FileItem
              file = process_file(child)
              file.representation = rep
              div << file
            when LIBIS::Ingester::DirItem
              div << process_children(child, rep, @mets.div(label: child.name))
            else
              # do nothing
          end
        end
        div
      end

      def process_file(item)

        # copy file to stream
        relative_path = item.namepath
        target_path = File.join('streams', relative_path)
        target_dir = File.join(@dirname, subdir)
        FileUtils.mkdir_p(target_dir)
        FileUtils.copy_entry(item.properties[:filename], File.join(target_dir, item.filename))

        file = @mets.file(
            label: item.name,
            mimetype: item.properties[:mimetype],
            location: relative_path,
            size: item.properties[:size],
            fixity_type: 'MD5',
            fixity_value: item.checksum('MD5'),
        )

        file.dc_record = item.metadata.data if file.metadata && file.metadata.format == 'DC'

        file
      end

    end
  end
end
