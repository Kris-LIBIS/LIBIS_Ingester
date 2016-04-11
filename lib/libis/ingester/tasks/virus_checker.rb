# encoding: utf-8

require 'libis/ingester'
require 'libis-tools'

module Libis
  module Ingester

      class VirusChecker < ::Libis::Ingester::Task

        parameter item_types: [Libis::Ingester::FileItem], frozen: true

        def pre_process(item)
          super
          skip_processing_item if item.options['virus_checked']
        end

        def process(item)

          debug 'Scanning file for viruses'

          # noinspection RubyResolve
          cmd_options = Libis::Ingester::Config.virusscanner['options']
          # noinspection RubyResolve
          result = Libis::Tools::Command.run Libis::Ingester::Config.virusscanner[:command], *cmd_options, item.fullpath
          raise Libis::WorkflowError, "Error during viruscheck: #{result[:err]}" unless result[:status]

          item.options['virus_checked'] = true
          debug 'File is clean'

        end

      end

  end
end
