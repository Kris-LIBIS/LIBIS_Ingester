# encoding: utf-8
require 'libis-ingester'

require_relative 'labeler'
require_relative 'base/csv_mapping'
module Libis
  module Ingester

    class LabelMapper < Libis::Ingester::Labeler
      include Libis::Ingester::CsvMapping

      parameter mapping_file: nil,
                description: 'Path of mapping file.'
      parameter mapping_format: 'csv',
                description: 'Format in which the mapping file is written.',
                constraint: %w'tsv csv'
      parameter mapping_headers: 'Name X Label',
                description: 'Headers for mapping file.'
      parameter ignore_empty_label: false,
                description: 'Ignore lines with empty label column.'
      parameter lookup_field: 'Name',
                description: 'The name of the lookup field in the mapping file.'
      parameter label_field: 'Label',
                description: 'The name of the label field in the mapping file.'
      parameter thumbnail_field: 'Thumbnail',
                description: 'The name of the thumbnail field in the mapping file.'

      parameter recursive: true
      parameter item_types: [Libis::Ingester::FileItem], frozen: true


      def apply_options(opts)
        super(opts)
        result = load_mapping(
            parameter(:mapping_file),
            parameter(:mapping_format),
            parameter(:mapping_headers),
            parameter(:lookup_field),
            parameter(:label_field),
            parameter(:thumbnail_field),
            parameter(:ignore_empty_label)
        )
        @mapping = result[:mapping]
        @thumbnails = result[:flagged]
      end

      protected

      def mapping(name, item)
        return name if @mapping.empty?
        label = @mapping[name]
        return label if label
        warn 'Could not find label in mapping table', item
        name
      end

      def thumbnail?(name)
        @thumbnails.include?(name)
      end

    end

  end
end
