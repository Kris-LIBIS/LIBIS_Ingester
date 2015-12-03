# encoding: utf-8

require 'libis/ingester'
require 'libis-tools'

module Libis
  module Ingester

      class VirusChecker < ::Libis::Ingester::Task

        parameter item_types: [Libis::Ingester::FileItem], frozen: true

        def pre_process(item)
          super
          skip_processing_item if item.options[:virus_check]
        end

        def process(item)

          debug 'Scanning file for viruses'

          # noinspection RubyResolve
          cmd_options = Config.virusscanner[:options]
          # noinspection RubyResolve
          result = Libis::Tools::Command.run Config.virusscanner[:command], *cmd_options, item.fullpath
          raise Libis::WorkflowError, "Error during viruscheck: #{result[:err]}" unless result[:status]

          item.options[:virus_check] = true
          info 'File is clean'

        end

      end

  end
end
