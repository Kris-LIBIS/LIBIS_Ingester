# encoding: utf-8
require 'libis/workflow/mongoid/config'

module Libis
  module Ingester

    class Config < ::Libis::Workflow::Mongoid::Config

      private

      def initialize
        super
        require_all(File.join(File.dirname(__FILE__), 'tasks'))
        self[:virusscanner] = {command: 'echo', options: {}}
      end

    end

  end
end
