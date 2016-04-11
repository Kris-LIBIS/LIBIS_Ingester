# encoding: utf-8

require 'libis/ingester'
require 'libis-tools'

module Libis
  module Ingester

      class DirVirusChecker < ::Libis::Ingester::Task

        parameter location: '.',
                  description: 'Directory to scan for viruses'

        parameter item_types: [Libis::Ingester::Run], frozen: true

        def process(item)

          raise Libis::Workflow::AbortError, "Location does not exist: #{parameter(:location)}." unless Dir.exists?(parameter(:location))

          debug 'Scanning directory %s for viruses', parameter(:location)

          # noinspection RubyResolve
          cmd_options = Libis::Ingester::Config.virusscanner['options'] + ['-r']
          # noinspection RubyResolve
          result = Libis::Tools::Command.run Libis::Ingester::Config.virusscanner[:command], *cmd_options, parameter(:location)
          raise Libis::WorkflowError, "Error during viruscheck: #{result[:err]}" unless result[:status]

          item.options['virus_checked'] = true
          debug 'Directory is clean'

        end

      end

  end
end
