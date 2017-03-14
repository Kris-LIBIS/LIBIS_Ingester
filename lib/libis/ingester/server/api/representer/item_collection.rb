require_relative 'base'

module Libis::Ingester::API::Representer
  module ItemCollection

    def self.included(klass)
      klass.include Base
      klass.include Roar::Contrib::Decorator::CollectionRepresenter
      klass.property :id, exec_context: :decorator, writable: false
      [:self, :first, :last, :prev, :next].each do |l|
        klass.link l do |opts|
          opts[:links][l]
        end
      end
    end

    def id
      nil
    end

  end
end