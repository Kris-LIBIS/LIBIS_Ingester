# encoding: utf-8

require 'libis/ingester'

require_relative 'metadata_collector'

module Libis
  module Ingester

    class MetadataSearchCollector < Libis::Ingester::MetadataCollector

      parameter field: nil,
                description: 'Field to search on. If nil (default) no search will be performed, ' +
                    'but a simple id lookup will happen instead.\n'

      parameter term: nil,
                description: 'Ruby expression that builds the search term to be used in the metadata lookup. ' +
                    'If no term is given, the item name will be used. Use match_regex and match_term to create ' +
                    'a term dynamically.' +
                    'Available data are: \n' +
                    '- item.filename: file name of the object, \n' +
                    '- item.filepath: relative path of the object, \n' +
                    '- item.fullpath: full path of the object, \n' +
                    '- item.name: name of the object.'

      parameter match_regex: nil,
                description: 'Regular expression to check against the \'match_term\' value. \n' +
                    'The results of the match can be used in the \'term\' parameter. \n' +
                    'If nil, no Regexp matching is performed.'
      parameter match_term: 'item.name',
                description: 'Ruby expression evaluating to the value to be checked against the \'match_regex\'.'

      protected

      def get_record(item)
        term = get_search_term(item)
        return nil if term.blank?

        item.properties['metadata_search_term'] = term
        item.save!

        @metadata_cache ||= {}

        @metadata_cache[term] ||= search(term)
        debug 'Metadata for item \'%s\' not found.', item.namepath unless @metadata_cache[term]

        @metadata_cache[term]
      end

      def get_search_term(item)
        if parameter(:match_regex)
          match_term = eval parameter(:match_term)
          return nil unless match_term =~ Regexp.new(parameter(:match_regex))
        end
        parameter(:term).blank? ? item.name : eval(parameter(:term))
      end

      def search(_)
        nil
      end

    end

  end
end
