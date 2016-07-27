# encoding: utf-8
require 'fileutils'
require 'libis/ingester'

require 'libis-format'
Libis::Format::Converter::Repository.get_converters

require 'libis/tools/extend/hash'

module Libis
  module Ingester

    class ManifestationBuilder < Libis::Ingester::Task

      parameter recursive: true, frozen: true

      parameter item_types: [Libis::Ingester::IntellectualEntity], frozen: true

      protected

      # noinspection RubyResolve
      def process(item)

        item.status_progress(self.namepath, 0, item.get_run.ingest_model.manifestations.count)

        # Build all manifestations
        item.get_run.ingest_model.manifestations.each do |manifestation|
          debug 'Building manifestation %s', manifestation.representation_info.name
          rep = item.representation(manifestation.name)
          unless rep
            rep = Libis::Ingester::Representation.new
            rep.representation_info = manifestation.representation_info
            rep.access_right = manifestation.access_right
            rep.name = manifestation.name
            rep.label = manifestation.label
            rep.parent = item
          end
          build_manifestation(rep, manifestation)
          rep.save!
          item.status_progress(self.namepath)
        end

        stop_processing_subitems

      end

      private

      # noinspection RubyResolve
      def build_manifestation(representation, manifestation)

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
          source_rep = from_manifestation &&
              representation.parent.representation(from_manifestation.name)
          source_items = source_rep && source_rep.get_items || representation.parent.originals

          convert_hash = convert_info.to_hash
          convert_hash[:name] = representation.name
          convert_hash[:id] = convert_info.id

          # Check if a generator is given
          case convert_info.generator
            when 'assemble_images'
              # The image assembly generator
              assemble_images source_items, representation, convert_hash
            when 'assemble_pdf'
              # The PDF assembly generator
              assemble_pdf source_items, representation, convert_hash
            when 'thumbnail'
              generate_thumbnail source_items, representation, convert_hash
            else
              # No generator - convert each source file according to the specifications
              representation.status_progress(self.namepath, 0, source_items.count)
              source_items.each do |item|
                convert item, representation, convert_hash
                representation.status_progress(self.namepath)
              end
              set_status representation, :DONE
          end
        end
      end

      def move_file(file, to_parent)
        debug "Moving '#{file.name}' to '#{to_parent.name}' in object tree."
        file = to_parent.move_item(file)
        process_files(file)
      end

      def process_files(file_or_div)
        if file_or_div.is_a?(Libis::Ingester::FileItem)
          register_file(file_or_div)
        else
          file_or_div.get_items.each { |file| process_files(file) }
        end
      end

      def generate_thumbnail(items, representation, convert_hash)
        source_id = representation.parent.properties['thumbnail_source']
        source_item = items.find('options.use_as_thumbnail' => true)
        source_item ||= source_id ? FileItem.find(source_id) : items.first
        convert(source_item, representation, convert_hash)
      end

      def assemble_images(items, representation, convert_hash)
        target_format = convert_hash[:target_format].to_sym
        assemble(
            items, representation, convert_hash[:source_formats],
            "#{representation.parent.name}_#{convert_hash[:name]}." +
                "#{Libis::Format::TypeDatabase.type_extentions(target_format).first}",
            convert_hash[:id]
        ) do |sources, new_file|
          Libis::Format::Converter::ImageConverter.new.
              assemble_and_convert(sources, new_file, target_format)
          unless convert_hash[:options].blank?
            convert_file(new_file, new_file, target_format, target_format, convert_hash[:options])
          end
        end
      end

      def assemble_pdf(items, representation, convert_hash)
        file_name = "#{convert_hash[:generated_file] ?
            eval(convert_hash[:generated_file]) :
            "#{representation.parent.name}_#{convert_hash[:name]}"
        }.pdf"
        assemble(items, representation, [:PDF], file_name, convert_hash[:id]) do |sources, new_file|
          Libis::Format::PdfMerge.run(sources, new_file)
          unless convert_hash[:options].blank?
            convert_file(new_file, new_file, :PDF, :PDF, convert_hash[:options])
          end
        end
      end

      def assemble(items, representation, formats, name, convert_id)
        return if representation.get_items.where(:'properties.convert_info' => convert_id).count > 0

        source_files = items.to_a.map do |item|
          # Collect all files from the list of items
          case item
            when Libis::Ingester::FileItem
              item
            when Libis::Ingester::Division
              item.all_files
            else
              nil
          end
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

        debug 'Building %s for %s from %d source files', new_file, representation.name, sources.count
        yield sources, new_file

        FileUtils.chmod('a+rw', new_file)

        assembly = Libis::Ingester::FileItem.new
        assembly.filename = new_file
        assembly.parent = representation
        assembly.properties['convert_info'] = convert_id
        format_identifier(assembly)
        register_file(assembly)
        assembly.save!
        assembly
      end

      def convert(item, new_parent, convert_hash)
        case item

          when Libis::Ingester::Division
            div = item
            unless convert_hash[:replace]
              div = item.dup
              div.parent = new_parent
              div.save!
              div
            end
            item.get_items.each { |child| convert(child, div, convert_hash) }

          when Libis::Ingester::FileItem

            return if new_parent.get_items.where(:'properties.converted_from' => item.id).count > 0

            mimetype = item.properties['mimetype']
            raise Libis::WorkflowError, 'File item %s format not identified.' % item unless mimetype

            type_id = Libis::Format::TypeDatabase.mime_types(mimetype).first

            unless convert_hash[:source_formats].blank?
              raise Libis::WorkflowError, 'File item %s format (%s) is not supported.' % [item, mimetype] unless type_id
              group = Libis::Format::TypeDatabase.type_group(type_id)
              check_list = [type_id, group].compact.map { |v| [v.to_s, v.to_sym] }.flatten
              return if (convert_hash[:source_formats] & check_list).empty?
            end

            if convert_hash[:target_format].blank?
              return move_file(item, new_parent)
            end

            src_file = item.fullpath
            new_file = File.join(
                item.get_run.work_dir,
                new_parent.id.to_s,
                item.id.to_s,
                [item.name,
                 convert_hash[:name],
                 extname(convert_hash[:target_format])
                ].join('.')
            )

            raise Libis::WorkflowError, 'File item %s format (%s) is not supported.' % [item, mimetype] unless type_id
            new_file, converter = convert_file(src_file, new_file, type_id, convert_hash[:target_format].to_sym, convert_hash[:options])
            return nil unless new_file

            FileUtils.chmod('a+rw', new_file)

            new_item = Libis::Ingester::FileItem.new
            new_item.name = item.name
            new_item.label = item.label
            new_item.parent = new_parent
            register_file(new_item)
            new_item.options = item.options
            new_item.properties['converter'] = converter
            new_item.properties['converted_from'] = item.id
            new_item.properties['convert_info'] = convert_hash[:id]
            new_item.filename = new_file
            format_identifier(new_item)
            new_item.save!
            new_item

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

      def convert_file(source_file, target_file, source_format, target_format, options = [{}])
        src_file = source_file
        src_format = source_format
        converterlist = []
        temp_files = []
        case options
          when Hash
            [options]
          when Array
            options
          else
            [{}]
        end.each do |opts|
          tgt_format = opts.delete(:target_format) || target_format
          tgt_file = tempfile(src_file, tgt_format)
          temp_files << tgt_file
          tgt_file = tgt_file.path
          src_file, converter = convert_one_file(src_file, tgt_file, src_format, tgt_format, opts)
          src_format = tgt_format
          converterlist << converter
        end
        converter = converterlist.join(' + ')
        FileUtils.mkpath(File.dirname(target_file))
        FileUtils.move(src_file, target_file, force: true)
        temp_files.each { |tmp_file| tmp_file.unlink }
        [target_file, converter]
      end

      def convert_one_file(source_file, target_file, source_format, target_format, options)
        converter = Libis::Format::Converter::Repository.get_converter_chain(
            source_format, target_format, options
        )

        unless converter
          raise Libis::WorkflowError,
                "Could not find converter for #{source_format} -> #{target_format} with #{options}"
        end

        converter_name = converter.to_s
        debug 'Converting file %s to %s with %s', source_file, target_file, converter_name
        converted = converter.convert(source_file, target_file)

        unless converted && converted == target_file
          error "File conversion failed (#{converter_name})."
          return [nil, converter_name]
        end

        [target_file, converter_name]
      end

      def format_identifier(item)
        format = Libis::Format::Identifier.get(item.fullpath) rescue {}

        mimetype = format[:mimetype]

        unless mimetype
          warn "Could not determine MIME type. Using default 'application/octet-stream'."
          mimetype = 'application/octet-stream'
        end

        item.properties['mimetype'] = mimetype
        item.properties['puid'] = format[:puid]
      end

      def tempfile(source_file, target_format)
        Tempfile.new([File.basename(source_file, '.*'), ".#{extname(target_format)}"])
      end

      def extname(format)
        Libis::Format::TypeDatabase.type_extentions(format).first
      end

    end

  end
end
