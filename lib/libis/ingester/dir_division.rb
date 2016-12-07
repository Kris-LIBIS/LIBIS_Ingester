require_relative 'division'
require 'libis/workflow/base/dir_item'

module Libis
  module Ingester

    class DirDivision < Libis::Ingester::Division
      include Libis::Workflow::Base::DirItem
    end

  end
end
