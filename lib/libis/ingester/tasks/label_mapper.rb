require 'libis-ingester'
require 'set'

require_relative 'labeler'
require_relative 'base/mapping'
module Libis
  module Ingester

    class LabelMapper < Libis::Ingester::Labeler
      include Libis::Ingester::Base::Mapping

      parameter label_field: 'Label',
                description: 'The name of the label field in the mapping file.'
      parameter thumbnail_field: nil,
                description: 'The name of the thumbnail field in the mapping file.'

      def apply_options(opts)
        super(opts)
        set = Set.new(parameter(:mapping_headers))
        set << parameter(:label_field)
        parameter(:mapping_headers, set.to_a)
        parameter(:required_fields, [parameter(:mapping_key), parameter(:label_field)])
        if parameter(:thumbnail_field)
          set = Set.new(parameter(:mapping_flags))
          set << parameter(:thumbnail_field)
          parameter(:mapping_flags, set.to_a)
        end
      end

      protected

      def get_label(name, item)
        return name if self.mapping.empty?
        label = self.lookup(name, parameter(:label_field))
        return label if label
        warn 'Could not find label in mapping table', item
        name
      end

      def thumbnail?(name)
        self.thumbnails.include?(name)
      end

      def thumbnails
        return @thumbnails if @thumbnails
        @thumbnails = self.flagged(parameter(:thumbnail_field)).flatten
      end

    end

  end
end
