require 'libis/tools/metadata/dublin_core_record'

require_relative 'metadata_collector'
require_relative 'base/mapping'
module Libis
  module Ingester

    class MetadataSpreadsheetMapper < MetadataCollector
      include Base::Mapping

      parameter mapping_headers: %w(objectname filename label)
      parameter mapping_key: 'filename'
      parameter mapping_value: nil
      parameter filter_keys: []

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
                description: 'Optional regular expression to check against the \'match_term\' value. \n' +
                    'The results of the match can be used in the \'term\' parameter. \n' +
                    'If nil, no Regexp matching is performed.'
      parameter match_term: 'item.name',
                description: 'Ruby expression evaluating to the value to be checked against the \'match_regex\'.'

      parameter ignore_empty_value: true

      protected

      def get_record(item)
        term = get_term(item)
        return nil if term.blank?

        data = lookup(term)
        if data.blank?
          debug "No metadata found for #{term}"
          return nil
        end

        record = Libis::Tools::Metadata::DublinCoreRecord.new
        data.each do |key,value|
          next unless key =~ /^<(dc(terms)?:[^>]+)>.*$/
          record.add_node $1, value
        end

        record
      end

      def get_term(item)
        if parameter(:match_regex)
          match_term = eval parameter(:match_term)
          return nil unless match_term =~ Regexp.new(parameter(:match_regex))
        end
        parameter(:term).blank? ? item.name : eval(parameter(:term))
      end

    end

  end
end