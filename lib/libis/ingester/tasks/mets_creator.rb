# encoding: utf-8
# encoding: utf-8
require 'fileutils'
require 'libis/ingester'
require 'libis/tools/metadata/marc21_record'
require 'libis/tools/metadata/mappers/kuleuven'
require 'libis/tools/checksum'

module Libis
  module Ingester

    class MetsCreator < Libis::Ingester::Task

      taskgroup :ingester

      parameter collection: nil,
                description: 'Collection to add the documents to.'

      parameter root_collection: nil,
                description: 'Root collection to add the collections to.'

      parameter copy_files: false,
                description: 'Copy file info ingest dir instead of creating a symbolic link'

      parameter force_label_to_title: false,
                description: 'Force the IE\'s label into the metadata\'s dc:title field'

      parameter recursive: true, frozen: true

      def pre_process(item)
        skip_processing_item unless item.is_a? Libis::Ingester::IntellectualEntity
      end

      def process(item)
        unless @ingest_dir
          @ingest_dir = item.get_run.ingest_dir

          debug "Preparing ingest in #{@ingest_dir}.", item
          FileUtils.rmtree @ingest_dir
          FileUtils.mkpath @ingest_dir
          FileUtils.chmod 'a+rwX', @ingest_dir
        end
        create_ie(item)
        stop_processing_subitems
      end

      # noinspection RubyResolve
      def create_item(item)

        check_item_type Libis::Ingester::Item, item

        case item
          when Libis::Ingester::IntellectualEntity
            create_ie item
          else
            item.get_items.each {|i| create_item(i)}
        end
      end

      # noinspection RubyResolve
      def create_ie(item)
        item.properties['ingest_sub_dir'] = "#{item._id}.#{item.name}"
        item.save!

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

        if dc_record.title.text.blank? || parameter(:force_label_to_title)
          debug "Setting DC title to '#{item.label}'"
          dc_record.title = item.label
        end

        collection_list = item.ancestors.select do |i|
          i.is_a? Libis::Ingester::Collection
        end.map do |collection|
          collection.label
        end
        collection_list << parameter(:collection) if parameter(:collection)
        collection_list << parameter(:root_collection) if parameter(:root_collection)

        dc_record.isPartOf = collection_list.reverse.join('/') unless collection_list.empty?

        ingest_model = item.get_run.ingest_model

        dc_record.identifier! ingest_model.identifier if ingest_model.identifier

        mets.dc_record = dc_record.root.to_xml

        amd = {
            status: item.properties['status'] || ingest_model.status || 'ACTIVE',
            entity_type: item.properties['entity_type'] || ingest_model.entity_type,
            user_a: item.properties['user_a'] || ingest_model.user_a,
            user_b: item.properties['user_b'] || ingest_model.user_b,
            user_c: item.properties['user_c'] || ingest_model.user_c,
        }

        access_right = ingest_model.access_right
        if item.properties['access_right']
          access_right = ::Libis::Ingester::AccessRight.find_by(name: item.properties['access_right'])
        end
        amd[:access_right] = access_right.ar_id if access_right

        retention_period = ingest_model.retention_period
        if item.properties['retention_period']
          retention_period = ::Libis::Ingester::RetentionPeriod.find_by(name: item.properties['retention_period'])
        end
        amd[:retention_period] = retention_period.rp_id if retention_period

        amd[:collection_id] = item.parent.properties['collection_id'] if item.parent.is_a?(Libis::Ingester::Collection)

        mets.amd_info = amd

        ie_ingest_dir = File.join @ingest_dir, item.properties['ingest_sub_dir']

        item.representations.each {|rep| add_rep(mets, rep, ie_ingest_dir)}

        mets_filename = File.join(ie_ingest_dir, 'content', "#{item.name}.xml")
        FileUtils.mkpath(File.dirname(mets_filename))
        mets.xml_doc.save mets_filename

        sip_dc = Libis::Tools::Metadata::DublinCoreRecord.new do |xml|
          xml[:dc].title "#{item.get_run.name} - #{item.namepath}"
        end

        sip_dc.save(File.join(ie_ingest_dir, 'content', 'dc.xml'))

        FileUtils.chmod_R 'a+rwX', ie_ingest_dir

        debug "Created METS file '#{mets_filename}'.", item
      end

      def add_rep(mets, item, ie_ingest_dir)

        rep = mets.representation(item.to_hash)
        rep.label = item.label
        div = mets.div label: item.parent.label
        mets.map(rep, div)

        add_children(mets, rep, div, item, ie_ingest_dir)

      end

      def add_children(mets, rep, div, item, ie_ingest_dir)
        item.divisions.each {|d| div << add_children(mets, rep, mets.div(d.name), d, ie_ingest_dir)}
        item.files.each {|f| div << add_file(mets, rep, f, ie_ingest_dir)}
        div
      end

      def add_file(mets, rep, item, ie_ingest_dir)
        config = item.to_hash
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
        config[:group_id] = properties[:group_id]
        config[:label] = item.label

        file = mets.file(config)

        file.representation = rep

        # copy file to stream
        stream_dir = File.join(ie_ingest_dir, 'content', 'streams')
        FileUtils.mkpath stream_dir
        target_path = File.join(stream_dir, file.target)
        if parameter(:copy_files)
          if File.exists?(target_path)
            unless Libis::Tools::Checksum.hexdigest(target_path, :MD5) == item.properties['checksum_md5']
              raise Libis::WorkflowError, 'Target file (%s) already exists with different content.' % [target_path]
            end
            debug "File copy of #{item.fullpath} skipped."
          else
            FileUtils.copy_entry(item.fullpath, target_path)
            debug "Copied file to #{target_path}.", item
          end
        else
          if File.exists?(target_path)
            unless Libis::Tools::Checksum.hexdigest(target_path, :MD5) == item.properties['checksum_md5']
              raise Libis::WorkflowError, 'Target link (%s) already exists with different content.' % [target_path]
            end
            debug "File linking of #{item.fullpath} skipped."
          else
            FileUtils.symlink(item.fullpath, target_path)
            debug "Linked file to #{target_path}.", item
          end
        end

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
