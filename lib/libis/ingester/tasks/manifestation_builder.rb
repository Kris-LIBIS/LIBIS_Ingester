# encoding: utf-8
require 'fileutils'
require 'tmpdir'
require 'libis/ingester'

require 'libis-format'
Libis::Format::Converter::Repository.get_converters

require 'libis/tools/extend/hash'
require_relative 'base/format'

module Libis
  module Ingester

    class ManifestationBuilder < Libis::Ingester::Task
      include ::Libis::Ingester::Base::Format

      taskgroup :preingester

      parameter on_convert_error: 'FAIL', type: :string, constraint: %w'FAIL DROP COPY',
                description: 'Action to take when a file conversion fails. Valid values are:\n' +
                    '- FAIL: report this as an error and stop processing the item\n' +
                    '- DROP: report this as an error and continue without the file\n' +
                    '- COPY: report the error and copy the source file instead\n' +
                    'Note that dropping the file may cause errors later, e.g. with empty representations.'

      parameter recursive: true, frozen: true

      parameter item_types: [Libis::Ingester::IntellectualEntity], frozen: true

      protected

      # noinspection RubyResolve
      def process(item)

        item.status_progress(self.namepath, 0, item.get_run.ingest_model.manifestations.count)

        # Build all manifestations
        item.get_run.ingest_model.manifestations.each do |manifestation|
          debug 'Building manifestation %s', item, manifestation.representation_info.name
          rep = item.representation(manifestation.name)
          unless rep
            rep = Libis::Ingester::Representation.new
            rep.representation_info = manifestation.representation_info
            rep.access_right = manifestation.access_right
            rep.name = manifestation.name
            rep.label = manifestation.label
            rep.parent = item
          end
          set_status(rep, :STARTED)
          build_manifestation(rep, manifestation)
          if rep.items.size == 0
            if manifestation.optional
              warn "Manifestation %s '%s' is marked optional and no items were found. Representation will not be created.",
                   item, manifestation.name, manifestation.label
              set_status(rep, :DONE)
              rep.destroy!
            else
              error "Representation %s is empty.", item, rep.name
              set_status(rep, :FAILED)
              raise Libis::WorkflowError, 'Could not find content for representation %s.' % [rep.name]
            end
          else
            set_status(rep, :DONE)
          end
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

          debug 'Processing convert_info [%s]', representation, convert_info.to_hash.to_s

          # Get the source files
          # - either from the given representation
          # - or the originals
          from_manifestation = convert_info.from_manifestation &&
              manifestation.ingest_model.manifestations.find_by(name: convert_info.from_manifestation)
          source_rep = from_manifestation &&
              representation.parent.representation(from_manifestation.name)
          # noinspection ConvertOneChainedExprToSafeNavigation
          source_items = source_rep&.get_items || representation.parent.originals

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
          when 'from_ie'
            generate_from_ie(representation, convert_hash)
          else
            # No generator - convert each source file according to the specifications
            representation.status_progress(self.namepath, 0, source_items.count)
            source_items.each do |item|
              convert item, representation, convert_hash if convert_hash[:source_files].blank? ||
                  Regexp.new(convert_hash[:source_files]).match(item.filename)
              representation.status_progress(self.namepath)
            end
          end
        end
      end

      def copy_file(file, to_parent)
        debug "Copying '%s' to '%s' in object tree.", to_parent, file.name, to_parent.name
        file = to_parent.copy_item(file)
        process_files(file)
      end

      def move_file(file, to_parent)
        debug "Moving '%s' to '%s' in object tree.", to_parent, file.name, to_parent.name
        file = to_parent.move_item(file)
        process_files(file)
      end

      def process_files(file_or_div)
        if file_or_div.is_a?(Libis::Ingester::FileItem)
          register_file(file_or_div)
        else
          file_or_div.get_items.each {|file| process_files(file)}
        end
      end

      def generate_thumbnail(items, representation, convert_hash)
        source_id = representation.parent.properties['thumbnail_source']
        source_item = items.find_by('options.use_as_thumbnail' => true)
        source_item ||= source_id ? FileItem.find_by(id: source_id) : items.first
        convert(source_item, representation, convert_hash)
      end

      def generate_from_ie(representation, convert_hash)
        ie = representation.parent
        ie.extend Libis::Workflow::Base::FileItem
        file = Libis::Ingester::FileItem.new
        file.filename = ie.fullpath
        format_identifier(file)
        convert(file, representation, convert_hash)
      end

      def assemble_images(items, representation, convert_hash)
        target_format = convert_hash[:target_format].to_sym
        assemble(
            items, representation, convert_hash[:source_formats],
            "#{representation.parent.name}_#{convert_hash[:name]}." +
                "#{Libis::Format::TypeDatabase.type_extentions(target_format).first}",
            convert_hash[:id]
        ) do |sources, new_file|
          options = nil
          options = convert_hash[:options] if convert_hash[:options] && convert_hash[:options].is_a?(Hash)
          options = convert_hash[:options].first if convert_hash[:options] && convert_hash[:options].is_a?(Array)
          sources = options ?
                        sources.map do |source|
                          source_file = source.fullpath
                          source_format = Libis::Format::TypeDatabase.mime_types(source.properties[:mimetype]).first
                          convert_file(source_file, nil, source_format, source_format, options)[0]
                        end :
                        sources.map {|source| source.fullpath}
          Libis::Format::Converter::ImageConverter.new.assemble_and_convert(sources, new_file, target_format)
          sources.each {|f| FileUtils.rm_f f} if options
          options = convert_hash[:options][1] rescue nil
          convert_file(new_file, new_file, target_format, target_format, options) if options
        end
      end

      def assemble_pdf(items, representation, convert_hash)
        file_name = "#{convert_hash[:generated_file] ?
                           Kernel.eval(convert_hash[:generated_file]) :
                           "#{representation.parent.name}_#{convert_hash[:name]}"
        }.pdf"
        assemble(items, representation, [:PDF], file_name, convert_hash[:id]) do |sources, new_file|
          source_files = sources.map {|file| file.fullpath}
          Libis::Format::Tool::PdfMerge.run(source_files, new_file)
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

        return if source_files.empty?

        new_file = File.join(
            representation.get_run.work_dir,
            representation.parent.id.to_s,
            name
        )

        FileUtils.mkpath(File.dirname(new_file))

        debug 'Building %s for %s from %d source files', representation, new_file, representation.name, source_files.count
        yield source_files, new_file

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
          item.get_items.each {|child| convert(child, div, convert_hash)}

        when Libis::Ingester::FileItem

          begin

            return if new_parent.get_items.where(:'properties.converted_from' => item.id).count > 0

            mimetype = item.properties['mimetype']
            raise Libis::WorkflowError, 'File item %s format not identified.' % [item] unless mimetype

            type_id = Libis::Format::TypeDatabase.mime_types(mimetype).first

            unless convert_hash[:source_formats].blank?
              unless type_id
                warn 'Ignoring file item (%s) with unsupported file format (%s) in format conversion.', item, mimetype
                return
              end
              group = Libis::Format::TypeDatabase.type_group(type_id)
              check_list = [type_id, group].compact.map {|v| [v.to_s, v.to_sym]}.flatten
              if (convert_hash[:source_formats] & check_list).empty?
                debug 'File item format (%s) does not match conversion criteria (%s)',
                      item, check_list.to_s, convert_hash[:source_formats].to_s
                return
              end
            end

            (convert_hash[:properties] || {}).each do |key, value|
              return nil unless item.properties[key] == value
            end

            if convert_hash[:target_format].blank?
              return copy_file(item, new_parent) if convert_hash[:copy_file]
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
            new_file_name, converter = convert_file(src_file, new_file, type_id, convert_hash[:target_format].to_sym, convert_hash[:options])
            new_file = new_file_name
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

          rescue ::RuntimeError => e
            case parameter(:on_convert_error)
            when 'COPY'
              copy_file(item, new_parent)
            when 'DROP'
              warn "Ignoring file '%s' because of error: '%s' @ '%s'", item.filepath, e.message, e.backtrace.first
              return
            else
              raise
            end
          end

        else
          # no action
        end
      end

      def match_file(file, formats)
        return true if formats.blank?
        mimetype = file.properties['mimetype']
        type_id = Libis::Format::TypeDatabase.mime_types(mimetype).first
        group = Libis::Format::TypeDatabase.type_group(type_id.to_s)
        check_list = [type_id, group].compact.map {|v| [v.to_s, v.to_sym]}.flatten
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
          opts = opts.dup
          tgt_format = opts.delete(:target_format) || target_format
          tgt_file = tempname(src_file, tgt_format)
          temp_files << tgt_file
          begin
            src_file, converter = convert_one_file(src_file, tgt_file, src_format, tgt_format, opts)
          rescue Exception => e
            raise Libis::WorkflowError, "File conversion of '%s' from '%s' to '%s' failed: %s @ %s" %
                [src_file, src_format, tgt_format, e.message, e.backtrace.first]
          end
          src_format = tgt_format
          converterlist << converter
        end
        converter = converterlist.join(' + ')
        if target_file
          FileUtils.mkpath(File.dirname(target_file))
          FileUtils.cp(src_file, target_file)
        else
          target_file = temp_files.pop
        end
        temp_files.each {|tmp_file| FileUtils.rm_f tmp_file}
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
        debug 'Converting file %s to %s with %s ', source_file, target_file, converter_name
        converted = converter.convert(source_file, target_file)

        unless converted && converted == target_file
          error 'File conversion failed (%s).', converter_name
          return [nil, converter_name]
        end

        [target_file, converter_name]
      end

      def format_identifier(item)
        result = Libis::Format::Identifier.get(item.fullpath, tool: :fido) || {}
        process_messages(result, item)
        apply_formats(item, result[:formats])
      end

      def tempname(source_file, target_format)
        # noinspection RubyResolve
        Dir::Tmpname.create(
            [File.basename(source_file, '.*'), ".#{extname(target_format)}"],
            Libis::Ingester::Config.tempdir
        ) {}
      end

      def extname(format)
        Libis::Format::TypeDatabase.type_extentions(format).first
      end

    end

  end
end
