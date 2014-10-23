# encoding: utf-8
require 'singleton'
require 'libis/workflow/mongoid/config'

module LIBIS
  module Ingester

    class Config
      include Singleton

      attr_accessor :virusscanner

      def self.virusscanner
        instance.virusscanner
      end

      def self.virusscanner=(dir)
        instance.virusscanner = dir
      end

      def method_missing(name, *args, &block)
        ::LIBIS::Workflow::Mongoid::Config.instance.send(name, *args, &block)
      end

      def self.const_missing(name)
        return ::LIBIS::Workflow::Mongoid::Config.const_get(name) if ::LIBIS::Workflow::Mongoid::Config.const_defined?(name)
        return ::LIBIS::Workflow::Config.const_get(name) if ::LIBIS::Workflow::Config.const_defined?(name)
        super(name)
      end

      private

      def initialize
        ::LIBIS::Workflow::Config.require_all(File.join(File.dirname(__FILE__), 'tasks'))
        @virusscanner = {command: 'echo', options: {}}
      end

    end

  end
end
