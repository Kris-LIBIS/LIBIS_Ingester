require_relative 'collection'
require 'libis/workflow/base/dir_item'

module Libis
  module Ingester

    class DirCollection < ::Libis::Ingester::Collection
      include Libis::Workflow::Base::DirItem
    end

  end
end
