# encoding: utf-8
require 'libis-workflow'
require 'libis-format'
require 'libis/ingester'

module Libis
  module Ingester

    class PdfAssembler < Libis::Ingester::Task

      parameter source_representation: 'ARCHIVE',
                description: 'Representation with the source PDFs are.'

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
        target_rep.save!

        generator = Libis::Format::PdfMerge

        files = source_rep.files.map { |file| file.fullpath }
        # noinspection RubyResolve
        new_file = File.join(item.get_run.workdir, "#{item.id}-#{target_rep.name}.pdf")

        generator.run(files, new_file)

        new_item = Libis::Ingester::FileItem.new
        new_item.filename = new_file
        new_item.parent = target_rep

      end

    end

  end
end
