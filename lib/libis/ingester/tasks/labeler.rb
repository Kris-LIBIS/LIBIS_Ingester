# encoding: utf-8
require 'libis-ingester'
require 'csv'

module Libis
  module Ingester

    class Labeler < Libis::Ingester::Task

      parameter lookup_expr: 'item.name',
                description: 'A Ruby expression that returns the lookup value.'

      parameter recursive: true

      parameter item_types: [Libis::Ingester::FileItem]

      protected

      def process(item)
        lookup = eval(parameter(:lookup_expr))
        label = mapping(lookup)
        if label
          item.label = label
          status_counter(item)
          item.save!
        end
      end

      def mapping(name)
        name
      end

    end

  end
end
