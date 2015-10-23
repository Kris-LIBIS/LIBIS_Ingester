# encoding: utf-8

require 'libis/ingester'
require 'libis/services/primo'

module Libis
  module Ingester

    class MetadataLimoCollector < ::Libis::Ingester::Task
      parameter host: 'http://opac.libis.be/X',
                description: 'URL of the search service.'
      parameter target: 'Opac'
      parameter index: 'sig'
      parameter base: 'LBS01'
      parameter match: nil,
                description: 'Regular expression to run against the file name of the file. \n' +
                    'The results of the match can be used in the \'term\' parameter. ' +
                    'If nil, no Regexp matching is performed.'
      parameter term: nil,
                description: 'Ruby expression that builds the search term to be used in the metadata lookup. Available data are: \n' +
                    'filename: file name of the object, \n' +
                    'filepath: file path of the object, \n' +
                    'name: name of the object.'


      def process(item)
        search_term = get_search_term(item)

      end

      private

      def get_search_term(item)
        search_term = item.name
        if parameter(:term)
          if parameter(:match)
            search_term = item.filename if obj.respond_to? :filename
            if search_term =~ parameter(:match)
              search_term = eval parameter(:term)
            end
          end
        end
        search_term
      end
    end

  end
end