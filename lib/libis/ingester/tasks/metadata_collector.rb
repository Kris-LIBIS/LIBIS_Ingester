# encoding: utf-8
require 'libis-tools'
require 'libis-workflow'
require 'libis/ingester'
Dir.glob(File.join(File.dirname(__FILE__), 'metadata_*_collector.rb')).each do |filepath|
  # noinspection RubyResolve
  require_relative(File.basename(filepath, '.rb'))
end

module Libis
  module Ingester

    class MetadataCollector < Libis::Ingester::Task
      parameter source: nil, constraint: %w[File Directory Limo Scope CollectiveAccess],
                description: 'Where to collect metadata from.'
      parameter configuration: {}, description: 'Collector-specific configuration parameters'

      def initialize(parent, cfg = {})
        super
        raise Libis::WorkflowError.new('No metadata source specified.') if parameter(:source).nil?
        begin
          collector_class = "Libis::Ingester::Metadata#{parameter(:source)}Collector".constantize
          self << collector_class.new(self, parameter(:configuration))
        rescue Exception => e
          raise Libis::WorkflowError.new("Failed to create #{collector_class} task (#{e.message}).")
        end
      end

    end

  end
end
