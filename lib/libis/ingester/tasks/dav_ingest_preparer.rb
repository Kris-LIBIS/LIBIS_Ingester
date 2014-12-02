# encoding: utf-8

require 'fileutils'
require 'pathname'

require 'LIBIS_Workflow'
require 'LIBIS_Tools'

require 'libis/ingester/run'
require 'libis/ingester/dav_dossier'
require 'libis/ingester/file_item'
require 'libis/ingester/dir_item'

module LIBIS
  module Ingester

    class DavIngestPreparer < ::LIBIS::Workflow::Task
      parameter ingest_dir: '/nas/vol04/dav_deposit_area',
                description: 'Directory where the ingest files are to be created.'
      parameter ingest_type: 'METS',
                description: 'Collect directories into METS structure or Collections',
                constraint: %w[Collection METS]
      parameter ie_entity_type: 'DAV_DOSSIER',
                description: 'Entity type of the IE.'
      parameter file_entity_type: 'DAV_FILE',
                description: 'Entity type of the files.'
      parameter user_a: nil,
                description: 'IE User defined value A.'
      parameter user_b: nil,
                description: 'IE User defined value B.'
      parameter user_c: nil,
                description: 'IE User defined value C.'
      parameter status: 'ACTIVE',
                description: 'IE status value.'
      parameter access_right: 'AR_EVERYONE',
                constraint: %w[AR_EVERYONE 361545 361546 361547],
                description: 'IE Access Right MID.'

      def process(item)
        check_item_type ::LIBIS::Ingester::Run, item

        @dirname = options[:ingest_dir]

        raise RuntimeError, 'No location given.' unless @dirname

        @dirname = File.join(@dirname, item.name)

        debug "Preparing ingest in #{@dirname}.", item
        FileUtils.rmtree @dirname

        item.items.map { |i| process_dossier(i) }

      end

      def process_dossier(item)

        check_item_type LIBIS::Ingester::DavDossier, item

        # @dossier_dir = @dirname
        # Enable below to create one ingest per dossier
        @dossier_dir = File.join(@dirname, item.filename)
        FileUtils.mkdir_p File.join(@dossier_dir, 'content', 'streams')
        item.properties[:ingest_sub_dir] = Pathname.new(@dossier_dir).relative_path_from(Pathname.new(options[:ingest_dir])).to_s
        item.save

        @mets = LIBIS::Tools::MetsFile.new

        # noinspection RubyResolve
        dc_record = LIBIS::Tools::DCRecord.new do |xml|
          xml[:dc].title item.name
          xml[:dc].identifier item.properties[:rmt_info][:folder][:referenceCode]
        end
        if item.properties[:disposition]
          dc_record.add 'dc:date', Date.new(item.properties[:disposition], 2, 1).rfc3339
        end

        @mets.dc_record = dc_record.root.to_xml

        @mets.amd_info = {
            entity_type: options[:ie_entity_type],
            user_a: options[:user_a],
            user_b: options[:user_b],
            user_c: options[:user_c],
            status: options[:status],
            access_right: options[:access_right],
            retention_id: (item.properties[:disposition] ? '361540' : 'NO_RETENTION'),
        }

        rep = @mets.representation(
            label: 'Archiefkopie',
            preservation_type: 'PRESERVATION_MASTER',
            usage_type: 'VIEW',
        )

        div = @mets.div label: item.name
        @mets.map(rep, div)

        process_children(item, rep, div)

        mets_filename = File.join(@dossier_dir, 'content', "#{item.filename}.xml")
        @mets.xml_doc.save mets_filename

        debug "Created METS file '#{mets_filename}'.", item

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
        relative_path = item.filepath

        file = @mets.file(
            label: item.name,
            location: relative_path,
            target_location: item.filelist[1..-1].join('/'),
            entity_type: options[:file_entity_type],
        )

        target_path = File.join(@dossier_dir, 'content', 'streams', file.target)
        target_list = target_path.split('/')[0...-1]
        FileUtils.mkpath(target_list.join('/'))
        FileUtils.copy_entry(item.fullpath, target_path)
        debug "Copied file to #{target_path}.", item

        if item.metadata && item.metadata.format == 'DC'
          dc = LIBIS::Tools::DCRecord.parse item.metadata.data
          file.dc_record = dc.root.to_xml
        end

        file
      end

    end
  end
end
