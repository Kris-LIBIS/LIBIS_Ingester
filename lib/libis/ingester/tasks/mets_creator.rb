# encoding: utf-8
require 'fileutils'
require 'libis/ingester'

module Libis
  module Ingester

    class MetsCreator < Libis::Ingester::Task

      parameter ingest_model: nil,
                description: 'Ingest model name for the configuration of the IE building process.'
      parameter ingest_dir: nil,
                description: 'Directory where the ingest files are to be created.'
      parameter collection: nil,
                description: 'Existing collection to add the documents to.'

      parameter subitems: false, frozen: true
      parameter recursive: false, frozen: true

      def process(item)

        check_item_type ::Libis::Ingester::Run, item

        ingest_model_name = parameter(:ingest_model) || 'default'
        @ingest_model ||= ::Libis::Ingester::IngestModel.find_by(name: ingest_model_name)
        raise WorkflowError, 'Ingest model %s not found.' % ingest_model_name unless @ingest_model

        raise RuntimeError, 'No location given.' unless parameter(:ingest_dir)
        ingest_dir = File.join(parameter(:ingest_dir), item.name)
        item.properties[:ingest_dir] = ingest_dir

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
        dc_record = Libis::Tools::Metadata::DublinCoreRecord.new do |xml|
          xml[:dc].title item.name
        end

        collection_list = item.ancestors.select do |i|
          i.is_a? Libis::Ingester::Collection
        end.map(&:name)
        collection_list << parameter(:collection) if parameter(:collection)

        dc_record.isPartOf = collection_list.reverse.join('/')

        mets.dc_record = dc_record.root.to_xml

        amd = {
            status: @ingest_model.status,
            entity_type: @ingest_model.entity_type,
            user_a: @ingest_model.user_a,
            user_b: @ingest_model.user_b,
            user_c: @ingest_model.user_c,
        }

        access_right = Libis::Ingester::AccessRight.find_by name: @ingest_model.access_right
        amd[:access_right] = access_right.ar_id if access_right

        retention_period = Libis::Ingester::RetentionPeriod.find_by name: @ingest_model.retention_period
        amd[:retention_period] = retention_period.rp_id if retention_period

        mets.amd_info = amd

        ie_ingest_dir = File.join(item.get_run.properties[:ingest_dir], item.properties[:ingest_sub_dir])

        item.representations.each { |rep| add_rep(mets, rep, ie_ingest_dir) }

        mets_filename = File.join(ie_ingest_dir, 'content', "#{item.name}.xml")
        mets.xml_doc.save mets_filename

        debug "Created METS file '#{mets_filename}'.", item
      end

      def add_rep(mets, item, ie_ingest_dir)

        rep = mets.representation(label: item.representation_info.info.compact)
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
        file = mets.file(
            label: item.name,
            location: item.filepath,
            target_location: item.filepath,
            entity_type: item.entity_type,
        )

        file.representation = rep

        # copy file to stream
        stream_dir = File.join(ie_ingest_dir, 'content', 'streams')
        FileUtils.mkpath stream_dir
        target_path = File.join(stream_dir, file.target)
        FileUtils.copy_entry(item.fullpath, target_path)
        debug "Copied file to #{target_path}.", item

        if item.metadata && item.metadata.format == 'DC'
          dc = Libis::Tools::Metadata::DublinCoreRecord.parse item.metadata.data
          file.dc_record = dc.root.to_xml
        end

        file
      end

    end

  end
end
