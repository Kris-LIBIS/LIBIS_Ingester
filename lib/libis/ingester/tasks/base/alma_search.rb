require 'libis/ingester'
require 'libis/services/alma/sru_service'
require 'libis/tools/metadata/marc21_record'
require 'libis/tools/parameter'
require 'open-uri'

module Libis
  module Ingester
    module Base

      module AlmaSearch
        def self.included(klass)
          fail("#{klass.name} should be a ParameterContainer.") unless klass.ancestors.include? Libis::Tools::ParameterContainer

          klass.parameter host: nil,
                          description: 'URL of the Alma web service.'
          klass.parameter library: '32KUL_LIBIS_NETWORK',
                          description: 'SRU institution code'
          klass.parameter converter: 'Kuleuven'
          klass.parameter field: 'alma.mms_id',
                          description: 'Alma field to search in'
        end


        protected

        def search(term)
          @alma ||= parameter(:host) ?
              ::Libis::Services::Alma::SruService.new(parameter(:host)) :
              ::Libis::Services::Alma::SruService.new

          field = parameter(:field) || 'alma.mms_id'
          result = @alma.search(field, URI::encode("\"#{term}\""), parameter(:library))
          warn "Multiple records found for #{field}=#{term}" if result.size > 1

          return result.empty? ? nil : ::Libis::Tools::Metadata::Marc21Record.new(result.first.root)

        rescue Exception => e
          raise ::Libis::WorkflowError, "Alma request failed: #{e.message}"
        end
      end

    end
  end
end