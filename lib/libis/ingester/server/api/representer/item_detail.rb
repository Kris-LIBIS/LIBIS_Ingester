require_relative 'base'

module Libis::Ingester::API::Representer
  module ItemDetail

    def self.included(klass)
      klass.include Base
      [:self, :all].each do |l|
        klass.link l do |opts|
          opts[:links][l]
        end
      end
    end

  end
end