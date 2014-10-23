# encoding: utf-8

require 'LIBIS_Workflow'
require 'LIBIS_Tools'

module LIBIS
  module Ingester

      class VirusChecker < ::LIBIS::Workflow::Task

        def process(item)

          return unless item_type? ::LIBIS::Ingester::FileItem, item
          return unless item_type? ::LIBIS::Workflow::WorkItem, item
          return unless item.options[:filename]

          if item.options[:virus_check]
            debug 'Skipping file. Already checked.'
            return
          end

          debug 'Scanning file for virusses'

          cmd_options = Config.virusscanner[:options]
          result = LIBIS::Tools::Command.run Config.virusscanner[:command], *cmd_options, item.filepath
          raise WorkflowError, "Error during viruscheck: #{result[:err]}" unless result[:status]

          item.options[:virus_check] = true
          info 'File is clean'

        end

      end

  end
end
