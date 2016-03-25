# encoding: utf-8
require 'fileutils'
require 'libis/ingester'

require 'libis-format'
Libis::Format::Converter::Repository.get_converters

require 'libis/tools/extend/hash'

module Libis
  module Ingester

    class ManifestationBuilder < Libis::Ingester::Task

      parameter subitems: true, frozen: true
      parameter recursive: true, frozen: true

      parameter item_types: [Libis::Ingester::IntellectualEntity], frozen: true

      protected

      # noinspection RubyResolve
      def process(item)

        # Build all manifestations
        item.get_run.ingest_model.manifestations.each do |manifestation|
          debug 'Building manifestation %s', manifestation.representation_info.name
          rep = Libis::Ingester::Representation.new
          rep.representation_info = manifestation.representation_info
          rep.access_right = manifestation.access_right
          rep.name = manifestation.name
          rep.label = manifestation.label
          rep.parent = item
          build_manifestation(rep, manifestation)
          rep.save!
        end

        stop_processing_subitems

      end

      private

      # noinspection RubyResolve
      def build_manifestation(representation, manifestation)

        @processed_files = Set.new

        # special case: no conversion info means to move the original files. This is typically the preservation master.
        if manifestation.convert_infos.empty?
          representation.parent.originals.each do |original|
            move_file(original, representation)
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
              representation.parent.representation(from_manifestation.name)
          source_items = source && source.items.dup || representation.parent.originals

          convert_hash = convert_info.to_hash
          convert_hash[:name] = representation.name
          # Check if a generator is given
          case convert_info.generator
            when 'assemble_images'
              # The image assembly generator
              assemble_images source_items, representation, convert_hash
            when 'assemble_pdf'
              # The PDF assembly generator
              assemble_pdf source_items, representation, convert_hash
            else
              # No generator - convert each source file according to the specifications
              source_items.each do |item|
                convert item, representation, convert_hash
              end
          end
        end
      end

      def move_file(file, to_parent)
        debug "Moving '#{file.name}' to '#{to_parent.name}'"
        file.parent = to_parent
        file.save!
        if file.is_a?(Libis::Ingester::FileItem)
          @processed_files << file.id
          register_file(file)
        end
      end

      def copy_file(file, to_parent)
        debug "Copying '#{file.name}' to '#{to_parent.name}'"
        new_file = file.dup
        new_file.parent = to_parent
        new_file.save!
        if file.is_a?(Libis::Ingester::FileItem)
          @processed_files << file.id
          register_file(new_file)
        end
        file.items.each { |item| copy_file(item, new_file) }
      end

      def assemble_images(items, representation, convert_hash)
        target_format = convert_hash[:target_format].to_sym
        assemble(
            items, representation, convert_hash[:source_formats],
            "#{representation.parent.name}_#{convert_hash[:name]}." +
                "#{Libis::Format::TypeDatabase.type_extentions(target_format).first}"
        ) do |sources, new_file|
          Libis::Format::Converter::ImageConverter.new.
              assemble_and_convert(sources, new_file, target_format)
          convert_file(new_file, new_file, target_format, target_format, convert_hash[:options]) unless convert_hash[:options].blank?
        end
      end

      def assemble_pdf(items, representation, convert_hash)
        file_name = "#{convert_hash[:generated_file] ?
            eval(convert_hash[:generated_file]) :
            "#{representation.parent.name}_#{convert_hash[:name]}"
        }.pdf"
        assemble(items, representation, [:PDF], file_name) do |sources, new_file|
          Libis::Format::PdfMerge.run(sources, new_file)
          unless convert_hash[:options].blank?
            convert_file(new_file, new_file, :PDF, :PDF, convert_hash[:options])
          end
        end
      end

      def assemble(items, representation, formats, name)
        source_files = items.map do |item|
          # Collect all files from the list of items
          case item
            when Libis::Ingester::FileItem
              item
            when Libis::Ingester::Division
              item.all_files
            else
              nil
          end
        end.flatten.compact.reject do |file|
          # @processed_files.include?(file.id)
          false
        end.select do |file|
          match_file(file, formats)
        end

        sources = source_files.map { |file| file.fullpath }

        return if sources.empty?

        new_file = File.join(
            representation.get_run.work_dir,
            representation.parent.id.to_s,
            name
        )

        FileUtils.mkpath(File.dirname(new_file))

        debug "Building '#{new_file}' for '#{representation.name}' from #{sources.count} source files"
        yield sources, new_file

        source_files.each { |file| @processed_files << file.id }

        assembly = Libis::Ingester::FileItem.new
        assembly.filename = new_file
        assembly.parent = representation
        register_file(assembly)
        assembly.save!
        assembly
      end

      def convert(item, new_parent, convert_hash)
        case item

          when Libis::Ingester::Division
            div = item.dup
            div.parent = new_parent
            div.save!
            item.items.each { |child| convert(child, div, convert_hash) }

          when Libis::Ingester::FileItem

            # return if @processed_files.include?(item.id)

            mimetype = item.properties['mimetype']
            raise Libis::WorkflowError, 'File item %s format not identified.' % item unless mimetype

            type_id = Libis::Format::TypeDatabase.mime_types(mimetype).first
            raise Libis::WorkflowError, 'File item %s format (%s) is not supported.' % [item, mimetype] unless type_id

            unless convert_hash[:source_formats].blank?
              group = Libis::Format::TypeDatabase.type_group(type_id)
              check_list = [type_id, group].compact.map { |v| [v.to_s, v.to_sym] }.flatten
              return if (convert_hash[:source_formats] & check_list).empty?
            end

            options = convert_hash[:options] || {}
            if options[:copy_file]
              return copy_file(item, new_parent)
            end

            if options[:move_file]
              return move_file(item, new_parent)
            end

            new_file = File.join(
                item.get_run.work_dir,
                item.id.to_s,
                new_parent.id.to_s,
                "#{File.basename(item.fullpath, '.*')}.#{convert_hash[:name]}." +
                    "#{Libis::Format::TypeDatabase.type_extentions(convert_hash[:target_format]).first}"
            )

            new_file, converter = convert_file(item.fullpath, new_file, type_id, convert_hash[:target_format].to_sym, options)
            return nil unless new_file

            @processed_files << item.id

            new_item = Libis::Ingester::FileItem.new
            new_item.filename = new_file
            new_item.name = item.name
            new_item.parent = new_parent
            new_item.properties['converter'] = converter
            new_item.properties['group_id'] = item.properties['group_id'] || item.id
            register_file(new_item)
            new_item.save!

          else
            # no action
        end
      end

      def match_file(file, formats)
        return true if formats.blank?
        mimetype = file.properties['mimetype']
        type_id = Libis::Format::TypeDatabase.mime_types(mimetype).first
        group = Libis::Format::TypeDatabase.type_group(type_id.to_s)
        check_list = [type_id, group].compact.map { |v| [v.to_s, v.to_sym] }.flatten
        return false if (formats & check_list).empty?
        true
      end

      private

      def register_file(new_file)
        new_file.properties['group_id'] = add_file_to_registry(new_file.label)
      end

      def add_file_to_registry(name)
        @file_registry ||= {}
        return @file_registry[name] if @file_registry.has_key?(name)
        @file_registry[name] = @file_registry.count + 1
      end

      def convert_file(source_file, target_file, source_format, target_format, options = {})
        converter = Libis::Format::Converter::Repository.get_converter_chain(
            source_format, target_format, options
        )

        unless converter
          raise Libis::WorkflowError,
                "Could not find converter for #{source_format} -> #{target_format} with #{options}"
        end

        converter_name = converter.to_s
        new_file = converter.convert(source_file, target_file)

        unless new_file
          error "File conversion failed (#{converter_name})."
          return [nil, converter_name]
        end

        [new_file, converter_name]

      end

    end

  end
end
