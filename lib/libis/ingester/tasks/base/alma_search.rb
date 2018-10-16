require 'libis/ingester'
require 'libis/services/alma/sru_service'
require 'libis/metadata/marc21_record'
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
          klass.parameter not_found: 'ignore',
                          description: 'What to do when record is not found',
                          enum: %w'ignore warn error abort'
        end


        protected

        def search(term)
          @alma ||= parameter(:host) ?
              ::Libis::Services::Alma::SruService.new(parameter(:host)) :
              ::Libis::Services::Alma::SruService.new

          field = parameter(:field) || 'alma.mms_id'
          result = @alma.search(field, URI::encode("\"#{term}\""), parameter(:library))
          warn "Multiple records found for #{field}=#{term}" if result.size > 1

          return ::Libis::Metadata::Marc21Record.new(result.first.root) unless result.empty?

          txt = "No records found for #{field}=#{term}"

          case parameter(:not_found)
          when 'warn'
            warn txt
          when 'error'
            error txt
          when 'abort'
            raise ::Libis::WorkflowError, txt
          else
            # ignore
          end

          nil

        rescue Exception => e
          raise ::Libis::WorkflowError, "Alma request failed: #{e.message}"
        end
      end

    end
  end
end