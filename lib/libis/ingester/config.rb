# encoding: utf-8

module Libis
  module Ingester

    # noinspection RubyConstantNamingConvention
    Config = ::Libis::Workflow::Mongoid::Config

    Config.require_all(File.join(File.dirname(__FILE__), 'tasks'))
    Config[:virusscanner] = {command: 'echo', options: []}

  end
end
