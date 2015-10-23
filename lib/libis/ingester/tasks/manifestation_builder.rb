# encoding: utf-8
require 'fileutils'
require 'libis/ingester'
require 'libis-format'

require 'libis/tools/extend/hash'

module Libis
  module Ingester

    class ManifestationBuilder < Libis::Ingester::Task

      parameter ingest_model: nil,
                description: 'Ingest model name for the configuration of manifestations.'

      parameter recursive: true

      # noinspection RubyResolve
      def process(item)

        return unless item.is_a? Libis::Ingester::IntellectualEntity

        ingest_model_name = parameter(:ingest_model) || 'default'
        ingest_model ||= ::Libis::Ingester::IngestModel.find_by name: ingest_model_name
        raise WorkflowError, 'Ingest model %s not found.' % ingest_model_name unless ingest_model

        # Build all manifestations
        ingest_model.manifestations.each do |manifestation|
          debug 'Building manifestation %s', manifestation.representation_info.name
          rep = Libis::Ingester::Representation.new
          rep.representation_info = manifestation.representation_info
          rep.access_right = manifestation.access_right
          rep.name = manifestation.name
          rep.label = manifestation.label
          rep.parent = item
          rep.save
          build_manifestation(rep, manifestation)
        end

      end

      # noinspection RubyResolve
      def build_manifestation(representation, manifestation)

        # special case: no conversion info means to copy the original files. This is typically the preservation master.
        if manifestation.convert_infos.empty?
          representation.parent.originals.each do |original|
            copy_file(original, representation)
          end
          return
        end

        # Perform each conversion
        manifestation.convert_infos.each do |convert_info|

          # Get the source files
          # - either from the given representation
          # - or the originals
          from_manifestation = convert_info.from_manifestation &&
              manifestation.ingest_model.manifestations.find_by(name: convert_info.from_manifestation)
          source = from_manifestation &&
              representation.parent.representation(from_manifestation.representation_info.name)
          source_items = source && source.items || representation.parent.originals

          info = convert_info.info
          info[:name] = representation.name
          # Check if a generator is given
          case convert_info.generator
            when 'assemble_images'
              # The image assembly generator
              assemble_images source_items, representation, info
            else
              # No generator - convert each source file according to the specifications
              source_items.each do |item|
                convert item, representation, info
              end
          end
        end
      end

      def copy_file(file, to_parent)
        new_file = file.dup
        new_file.parent = to_parent
        new_file.save!
        file.items.each {|item| copy_file(item, new_file)}
      end

      def assemble_images(items, representation, info)

        sources = items.map do |item|
          # Collect all files from the list of items
          case item
            when Libis::Ingester::FileItem
              item
            when Libis::Ingester::Division
              item.all_files
            else
              nil
          end
        end.flatten.compact.select do |file|
          # Check if the file format fits the requirements
          next(true) if info[:source_formats].nil? || info[:source_formats].empty?
          mimetype = file.properties[:mimetype]
          next(false) unless mimetype
          type_id = Libis::Format::TypeDatabase.mime_types(mimetype).first
          next(false) unless type_id
          group = Libis::Format::TypeDatabase.type_group(type_id)
          next(false) if (info[:source_formats] & [type_id.to_sym, type_id.to_s, group.to_sym, group.to_s]).empty?
          true
        end.map { |file| file.fullpath }

        return if sources.empty?

        generator = Libis::Format::Converter::ImageConverter.new

        # TODO: apply options to the converter.
        # Something like:
        # generator.apply_options(info[:options])

        new_file = File.join(
            representation.get_run.work_dir,
            representation.parent.id.to_s,
            "#{info[:name]}.#{Libis::Format::TypeDatabase.type_extentions(info[:target_format].to_sym).first}"
        )

        FileUtils.mkpath(File.dirname(new_file))

        generator.assemble_and_convert(sources, new_file , info[:target_format] || :TIFF)

        assembly = Libis::Ingester::FileItem.new
        assembly.filename = new_file
        assembly.parent = representation
        assembly.save!
      end

      def convert(item, new_parent, info)
        case item

          when Libis::Ingester::Division
            div = item.dup
            div.parent = new_parent
            div.save!
            item.items.each { |child| convert(child, div, info)}

          when Libis::Ingester::FileItem
            mimetype = item.properties[:mimetype]
            raise WorkflowError, 'File item %s format not identified.' % item unless mimetype

            type_id = Libis::Format::TypeDatabase.mime_types(mimetype).first
            raise WorkflowError, 'File item %s format (%s) is not supported.' % [item, mimetype] unless type_id

            unless info[:source_formats].nil? || info[:source_formats].empty?
              group = Libis::Format::TypeDatabase.type_group(type_id)
              return if (info[:source_formats] & [type_id.to_sym, type_id.to_s, group.to_sym, group.to_s]).empty?
            end


            options = info[:options]
            options.key_strings_to_symbols!(recursive: true, downcase: true) if options && options.is_a?(Hash)
            converter = Libis::Format::Converter::Repository.get_converter_chain(
                type_id, info[:target_format].to_sym, options
            )

            unless converter
              raise WorkflowError,
                    "Could not find converter for #{type_id} -> #{info[:target_format]} with #{info[:options]}"
            end

            path = item.fullpath

            new_file = File.join(
                item.get_run.work_dir,
                item.id.to_s,
                new_parent.id.to_s,
                "#{File.basename(item.fullpath, '.*')}.#{info[:name]}.#{Libis::Format::TypeDatabase.type_extentions(info[:target_format]).first}"
            )
            new_file = converter.convert(path, new_file)

            unless new_file
              error 'File conversion failed.'
              return nil
            end

            new_item = Libis::Ingester::FileItem.new
            new_item.filename = new_file
            new_item.parent = new_parent
            new_item.save!

          else
            # no action
        end
      end

    end

  end
end
