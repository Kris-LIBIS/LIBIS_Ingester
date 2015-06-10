# encoding: utf-8
require 'LIBIS_Workflow'
require 'LIBIS_Tools'

module Libis
  module Ingester

    class MetadataCollector < Libis::Workflow::Task
      parameter source: nil, constraint: %w[mapfile directory Aleph Scope CollectiveAccess]

    end

  end
end
