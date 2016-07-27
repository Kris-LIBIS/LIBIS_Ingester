# encoding: utf-8

require 'libis/ingester'

require_relative 'base/csv_mapping'

module Libis
  module Ingester

    class MetadataCollector < Libis::Ingester::Task
      include Libis::Ingester::CsvMapping

      parameter item_types: %w'Libis::Ingester::IntellectualEntity Libis::Ingester::Collection',
                description: 'Items types to process for metadata.'
      parameter recursive: true, frozen: true

      parameter field: nil,
                description: 'Field to search on. If nil (default) no search will be performed, ' +
                    'but a simple id lookup will happen instead.\n'

      parameter term: nil,
                description: 'Ruby expression that builds the search term to be used in the metadata lookup. ' +
                    'If no term is given, the item name will be used. Use match_regex and match_term to create ' +
                    'a term dynamically.'
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

      parameter converter: 'Kuleuven',
                description: 'Dublin Core metadata converter to use.',
                constraint: %w[Kuleuven Flandrica]

      parameter mapping_file: nil,
                description: 'File that maps search term to identifier for metadata lookup.'

      parameter mapping_format: 'csv',
                description: 'Format in which the mapping file is written.',
                constraint: %w'tsv csv'

      parameter mapping_headers: %w'Name MMS',
                description: 'Headers for the mapping file.'

      parameter mapping_key: 'Name',
                description: 'Field name for the column that contains the lookup value.'

      parameter mapping_value: 'MMS',
                description: 'Field name for the column that contains the search value.'

      parameter ignore_empty_value: false,
                description: 'Ingore lines with empty value column.'

      parameter title_to_name: false,
                description: 'Update the item name with the title in the metadata?'

      parameter title_to_label: true,
                description: 'Update the item label with the title in the metadata?'

      parameter new_name: nil,
                description: 'Ruby expression that transforms the name.'

      parameter new_label: nil,
                description: 'Ruby expression that transforms the label.'

      parameter fail_on_not_found: false,
                description: 'Raise an error if a metadata record cannot be found?'

      def apply_options(opts)
        super(opts)
        @mapping = load_mapping(
            file: parameter(:mapping_file),
            format: parameter(:mapping_format),
            headers: parameter(:mapping_headers),
            key: parameter(:mapping_key),
            value: parameter(:mapping_value),
            ignore_empty_value: parameter(:ignore_empty_value)
        )[:mapping]
      end

      protected

      def process(item)
        record = get_record(item)
        return unless record
        record = convert_metadata(record)
        assign_metadata(item, record)
      rescue Exception => e
        error 'Error getting metadata: %s', e.message
        debug 'At: %s', e.backtrace.first
        set_status(item, :FAILED)
      end

      def get_search_term(item)
        if parameter(:match_regex)
          match_term = eval parameter(:match_term)
          return nil unless match_term =~ Regexp.new(parameter(:match_regex))
        end
        search_term = parameter(:term).blank? ? item.name : eval(parameter(:term))
        lookup search_term
      end

      private

      def get_record(item)
        term = get_search_term(item)
        return nil if term.blank?

        item.properties['metadata_search_term'] = term
        item.save!

        @metadata_cache ||= {}

        unless @metadata_cache[term]
          @metadata_cache[term] = search(term)
          debug 'Metadata for item \'%s\' not found.', item.namepath unless @metadata_cache[term]
        end

        @metadata_cache[term]
      end

      def search(_)
        nil
      end

      def assign_metadata(item, record)
        metadata_record = Libis::Ingester::MetadataRecord.new
        metadata_record.format = 'DC'
        metadata_record.data = record.to_xml
        # noinspection RubyResolve
        item.metadata_record = metadata_record
        info 'Metadata added to \'%s\'', item, item.name
        transform_item(item, record.title.content)
        item.save!
      end

      def transform_item(item, title)
        item.name = title if parameter(:title_to_name)
        item.name = eval(parameter(:new_name)) if parameter(:new_name)
        item.label = title if parameter(:title_to_label)
        item.label = eval(parameter(:new_label)) if parameter(:new_label)
      end

      def convert_metadata(record)
        return record unless parameter(:converter)
        mapper_class = "Libis::Tools::Metadata::Mappers::#{parameter(:converter)}".constantize
        record.extend mapper_class
        record.to_dc
      end

      def lookup(term)
        return term if @mapping.blank?
        @mapping[term]
      end
    end

  end
end
