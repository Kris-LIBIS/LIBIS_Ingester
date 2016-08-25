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
        label = mapping(lookup, item)
        if label
          item.label = label
          item.save!
          debug 'Item %s labeled as %s', item, item.name, item.label
        end
        if thumbnail?(lookup)
          item.options['use_as_thumbnail'] = true
          debug 'Item %s marked as thumbnail', item, item.name
        end
      end

      def mapping(name, _item)
        name
      end

      def thumbnail?(name)
        false
      end

    end

  end
end
