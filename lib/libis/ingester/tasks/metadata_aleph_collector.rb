# encoding: utf-8

require 'LIBIS_Tools'
require 'LIBIS_Workflow'

module LIBIS
  module Ingester

    class MetadataAlephCollector < ::LIBIS::Workflow::Task
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
                    'name: name of the object. \n'


      def process(item)
        search_term = get_search_term(item)

      end

      private

      def get_search_term(item)
        search_term = item.name
        if options[:term]
          if options[:match]
            search_term = item.filename if obj.respond_to? :filename
            if search_term =~ options[:match]
              search_term = eval options[:term]
            end
          end
        end
        search_term
      end
    end

  end
end