# encoding: utf-8
require 'libis-workflow'
require 'libis-format'
require 'libis/ingester'

module Libis
  module Ingester

    class ImageAssembler < Libis::Ingester::Task

      parameter source_formats: [],
                description: 'Only process formats of these types.'

      parameter target_format: :TIFF,
                description: 'Format of the target file with the assembled images.'

      parameter source_representation: 'ARCHIVE',
                description: 'Representation with the source images are.'

      parameter target_representation: 'VIEW',
                description: 'Representation for the assembly.'

      parameter access_right: 'public',
                description: 'Access right for the assembly.'

      parameter recursive: true

      def process(item)

        return unless item.is_a? Libis::Ingester::IntellectualEntity

        source_rep = item.representations.find { |rep| rep.name == parameter(:source_representation) }
        raise Libis::WorkflowError, 'Representation %s not found.' % parameter(:source_representation) unless source_rep

        target_rep = item.representations.find { |rep| rep.name == parameter(:target_representation) }
        raise Libis::WorkflowError, 'Representation %s exists.' % parameter(:target_representation) if target_rep

        rep_info = Libis::Ingester::RepresentationInfo.find_by(name: parameter(:target_representation))
        raise Libis::WorkflowError, 'Unknown representation %s.' % parameter(target_rep) unless rep_info

        target_rep = Libis::Ingester::Representation.new
        target_rep.representation_info = rep_info

        ar = Libis::Ingester::AccessRight.find_by(name: parameter(:access_right))
        raise Libis::WorkflowError, 'Unknown access right %s.' % parameter(parameter(:access_right)) unless ar
        target_rep.access_right = ar

        target_rep.parent = item
        target_rep.save

        generator = Libis::Format::Converter::ImageConverter.new

        files = source_rep.files.select do |file|
          next(true) if parameter(:source_formats).nil? || parameter(:source_formats).empty?
          mimetype = file.properties[:mimetype]
          next(false) unless mimetype
          type_id = Libis::Format::TypeDatabase.mime_types(mimetype).first
          next(false) unless type_id
          group = Libis::Format::TypeDatabase.type_group(type_id)
          next(false) if (parameter(:source_formats) & [type_id.to_sym, type_id.to_s, group.to_sym, group.to_s]).empty?
          true
        end.map { |file| file.fullpath }
        # noinspection RubyResolve
        new_file = Tempfile.new(
            [
                target_rep.name,
                ".#{Libis::Format::TypeDatabase.type_extentions(parameter(:target_format)).first}"
            ],
            item.get_run.workdir,
        )

        generator.assemble_and_convert(files, new_file , parameter(:target_format))

        new_item = Libis::Ingester::FileItem.new
        new_item.filename = new_file
        new_item.parent = target_rep

      end

    end

  end
end
