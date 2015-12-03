# encoding: utf-8

require 'libis/ingester'

module Libis
  module Ingester

    class MetadataCollector < Libis::Ingester::Task

      parameter item_types: %w'Libis::Ingester::IntellectualEntity Libis::Ingester::Collection',
                description: 'Items types to process for metadata.'
      parameter recursive: true, frozen: true

      parameter match_regex: nil,
                description: 'Regular expression to check against the \'match_term\' value. \n' +
                    'The results of the match can be used in the \'term\' parameter. \n' +
                    'If nil, no Regexp matching is performed.'
      parameter match_term: 'item.name',
                description: 'Ruby expression evaluating to the value to be checked against the \'match_regex\'.'

      parameter term: nil,
                description: 'Ruby expression that builds the search term to be used in the metadata lookup. ' +
                    'If no term is given, the item name will be used.'
                    'Available data are: \n' +
                    'item.filename: file name of the object, \n' +
                    'item.filepath: relative path of the object, \n' +
                    'item.fullpath: full path of the object, \n' +
                    'item.name: name of the object.'

      parameter converter: nil,
                description: 'Dublin Core metadata converter to use.',
                constraint: %w[Kuleuven Flandrica]

      parameter mapping_file: nil,
                description: 'File that maps search term to identifier for metadata lookup.'
      parameter mapping_format: 'tsv',
                description: 'Format in which the mapping file is written.',
                constraint: %w'tsv csv'

      parameter title_to_name: true,
                description: 'Update the item name with the title in the metadata?'

      def apply_options(opts)
        super(opts)
        @mapping = {}
        mapping_file = parameter(:mapping_file)
        return if mapping_file.blank?
        unless File.exist?(mapping_file) && File.readable?(mapping_file)
          raise Libis::WorkflowError, "Cannot open mapping file '#{mapping_file}'"
        end
        open(mapping_file) do |file|
          file.each_line do |line|
            case parameter(:mapping_format)
              when 'tsv'
                if /^(.*)\t+(.*)$/.match(line.strip)
                  @mapping[$1] = $2
                end
              when 'csv'
                if /^"?(.*)"?\s*,\s*"?(.*)"?$/.match(line.strip)
                  @mapping[$1] = $2
                end
              else
                # do nothing
            end
          end
        end
      end

      protected

      def process(item)
        record = get_record(item)
        return unless record
        record = convert_metadata(record)
        assign_metadata(item, record)
      rescue Exception => e
        warn 'Failed to get metadata: %s', e.message
      end

      def get_search_term(item)
        if parameter(:match_regex)
          match_term = eval parameter(:match_term)
          return nil unless match_term =~ Regexp.new(parameter(:match_regex))
        end
        search_term = parameter(:term).blank? ?
            eval(parameter(:term)) :
            item.name
        lookup search_term
      end

      private

      def get_record(item)
        nil
      end

      def assign_metadata(item, record)
        metadata_record = Libis::Ingester::MetadataRecord.new
        metadata_record.format = 'DC'
        metadata_record.data = record.to_xml
        # noinspection RubyResolve
        item.metadata_record = metadata_record
        item.name = record.title if parameter(:title_to_name)
        info 'Metadata added to \'%s\'', item, item.name
        item.save
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
