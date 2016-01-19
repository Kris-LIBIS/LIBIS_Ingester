# encoding: utf-8
# encoding: utf-8
require 'fileutils'
require 'libis/ingester'
require 'libis/tools/metadata/marc21_record'
require 'libis/tools/metadata/mappers/kuleuven'

module Libis
  module Ingester

    class MetsCreator < Libis::Ingester::Task

      parameter collection: nil,
                description: 'Collection to add the documents to.'

      parameter subitems: false, frozen: true
      parameter recursive: false, frozen: true

      parameter item_types: [Libis::Ingester::Run], frozen: true

      def process(item)
        ingest_dir = item.ingest_dir

        debug "Preparing ingest in #{ingest_dir}.", item
        FileUtils.mkpath ingest_dir
        FileUtils.rmtree ingest_dir

        item.items.each { |i| create_item(i) }

      end

      # noinspection RubyResolve
      def create_item(item)

        check_item_type Libis::Ingester::Item, item

        case item
          when Libis::Ingester::IntellectualEntity
            create_ie item
          else
            item.items.each { |i| create_item(i) }
        end
      end

      # noinspection RubyResolve
      def create_ie(item)
        item.properties[:ingest_sub_dir] = "#{item._id}.#{item.name}"
        item.save

        mets = Libis::Tools::MetsFile.new

        dc_record = if item.metadata_record
                      case item.metadata_record.format
                        when 'DC'
                          Libis::Tools::Metadata::DublinCoreRecord.new(item.metadata_record.data)
                        else
                          nil
                      end
                    else
                      Libis::Tools::Metadata::DublinCoreRecord.new
                    end

        dc_record.title = item.name

        collection_list = item.ancestors.select do |i|
          i.is_a? Libis::Ingester::Collection
        end.map do |collection|
          collection.name
        end
        collection_list << parameter(:collection) if parameter(:collection)

        dc_record.isPartOf = collection_list.reverse.join('/') unless collection_list.empty?

        mets.dc_record = dc_record.root.to_xml

        ingest_model = item.get_run.ingest_model

        amd = {
            entity_type: ingest_model.entity_type,
            user_a: ingest_model.user_a,
            user_b: ingest_model.user_b,
            user_c: ingest_model.user_c,
        }

        access_right = ingest_model.access_right
        amd[:access_right] = access_right.ar_id if access_right

        retention_period = ingest_model.retention_period
        amd[:retention_period] = retention_period.rp_id if retention_period

        amd[:collection_id] = item.parent.properties[:collection_id] if item.parent.is_a?(Libis::Ingester::Collection)

        mets.amd_info = amd

        ie_ingest_dir = File.join item.get_run.ingest_dir, item.properties[:ingest_sub_dir]

        item.representations.each { |rep| add_rep(mets, rep, ie_ingest_dir) }

        mets_filename = File.join(ie_ingest_dir, 'content', "#{item.name}.xml")
        mets.xml_doc.save mets_filename

        debug "Created METS file '#{mets_filename}'.", item
      end

      def add_rep(mets, item, ie_ingest_dir)

        rep = mets.representation(item.info)
        div = mets.div label: item.parent.name
        mets.map(rep, div)

        add_children(mets, rep, div, item, ie_ingest_dir)

      end

      def add_children(mets, rep, div, item, ie_ingest_dir)
        item.divisions.each { |d| div << add_children(mets, rep, mets.div(d.name), d, ie_ingest_dir) }
        item.files.each { |f| div << add_file(mets, rep, f, ie_ingest_dir) }
        div
      end

      def add_file(mets, rep, item, ie_ingest_dir)
        config = item.info
        properties = config.delete(:properties)
        config[:creation_date] = properties[:creation_time]
        config[:modification_date] = properties[:modification_time]
        config[:entity_type] = item.entity_type
        config[:location] = properties[:filename]
        config[:target_location] = item.filepath
        config[:mimetype] = properties[:mimetype]
        config[:size] = properties[:size]
        config[:puid] = properties[:puid]
        config[:checksum_MD5] = properties[:checksum_md5]
        config[:checksum_SHA1] = properties[:checksum_sha1]
        config[:checksum_SHA256] = properties[:checksum_sha256]
        config[:checksum_SHA384] = properties[:checksum_sha384]
        config[:checksum_SHA512] = properties[:checksum_sha512]
        config[:label] = item.name

        file = mets.file(config)

        file.representation = rep

        # copy file to stream
        stream_dir = File.join(ie_ingest_dir, 'content', 'streams')
        FileUtils.mkpath stream_dir
        target_path = File.join(stream_dir, file.target)
        FileUtils.copy_entry(item.fullpath, target_path)
        debug "Copied file to #{target_path}.", item

        # noinspection RubyResolve
        if item.metadata_record && item.metadata_record.format == 'DC'
          dc = Libis::Tools::Metadata::DublinCoreRecord.parse item.metadata_record.data
          file.dc_record = dc.root.to_xml
        end

        file
      end

    end

  end
end
