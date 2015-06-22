# encoding: utf-8

require 'libis/ingester'
require 'libis-tools'

module Libis
  module Ingester

      class VirusChecker < ::Libis::Ingester::Task

        def process(item)

          return unless item_type? ::Libis::Ingester::FileItem, item
          return unless item_type? ::Libis::Ingester::WorkItem, item
          return unless item.options[:filename]

          if item.options[:virus_check]
            debug 'Skipping file. Already checked.'
            return
          end

          debug 'Scanning file for virusses'

          # noinspection RubyResolve
          cmd_options = Config.virusscanner[:options]
          # noinspection RubyResolve
          result = Libis::Tools::Command.run Config.virusscanner[:command], *cmd_options, item.fullpath
          raise WorkflowError, "Error during viruscheck: #{result[:err]}" unless result[:status]

          item.options[:virus_check] = true
          info 'File is clean'

        end

      end

  end
end
