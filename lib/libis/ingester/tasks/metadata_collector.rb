# encoding: utf-8
require 'libis-tools'
require 'libis/ingester'

module Libis
  module Ingester

    class MetadataCollector < Libis::Ingester::Task
      parameter source: nil, constraint: %w[mapfile directory Aleph Scope CollectiveAccess]

    end

  end
end
