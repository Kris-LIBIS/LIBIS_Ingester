# encoding: utf-8
require 'pathname'

require 'libis/ingester'

module Libis
  module Ingester

    class IngestBuilder < Libis::Ingester::Task

      parameter ingest_dir: '/nas/vol04/ingest',
                description: 'Directory where the ingest files are to be created.'
      parameter ingest_model: nil,
                description: 'Ingest model name for the configuration of the IE building process.'

      parameter subitems: false
      parameter recursive: false

      def process(item)

        check_item_type ::Libis::Ingester::Run, item

        ingest_model_name = parameter(:ingest_model) || 'default'
        @ingest_model ||= ::Libis::Ingester::IngestModel.find_by(name: ingest_model_name)
        raise WorkflowError, 'Ingest model %s not found.' % ingest_model_name unless @ingest_model

        raise RuntimeError, 'No location given.' unless parameter(:ingest_dir)
        @ingest_dir = Pathname.new(parameter(:ingest_dir)) + item.name

        debug "Preparing ingest in #{@ingest_dir}.", item
        @ingest_dir.mkpath
        @ingest_dir.rmtree

        item.items.each { |i| create_ingest(i) }

      end

      # noinspection RubyResolve
      def create_ingest(item)

        check_item_type Libis::Ingester::Item, item

        unless item.is_a? Libis::Ingester::IntellectualEntity
          item.items.each { |i| create_ingest(i) }
          return
        end

        @ie_dir = @ingest_dir + "#{item._id}.#{item.name}"

        item.properties[:ingest_sub_dir] = @ie_dir.relative_path_from(Pathname.new(parameter(:ingest_dir))).to_s
        item.save

        mets = Libis::Tools::MetsFile.new
        dc_record = Libis::Tools::DCRecord.new do |xml|
          xml[:dc].title item.name
        end

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

        item.representations.each { |rep| add_rep(mets, rep) }

        mets_filename = @ie_dir + 'content' + "#{item.name}.xml"
        mets.xml_doc.save mets_filename.to_s

        debug "Created METS file '#{mets_filename}'.", item
      end

      def add_rep(mets, item)

        rep = mets.representation(label: item.representation_info.info.compact)
        div = mets.div label: item.parent.name
        mets.map(rep, div)

        add_children(mets, rep, div, item)

      end

      def add_children(mets, rep, div, item)
        item.divisions.each { |d| div << add_children(mets, rep, mets.div(d.name), d) }
        item.files.each { |f| div << add_file(mets, rep, f) }
        div
      end

      def add_file(mets, rep, item)
        file = mets.file(
            label: item.name,
            location: item.filepath,
            target_location: item.filepath,
            entity_type: item.entity_type,
        )

        file.representation = rep

        # copy file to stream
        stream_dir = @ie_dir + 'content' + 'streams'
        stream_dir.mkpath
        target_path = stream_dir + file.target
        FileUtils.copy_entry(item.fullpath, target_path)
        debug "Copied file to #{target_path}.", item

        if item.metadata && item.metadata.format == 'DC'
          dc = Libis::Tools::DCRecord.parse item.metadata.data
          file.dc_record = dc.root.to_xml
        end

        file
      end

    end

  end
end
