require_relative 'base'

module Libis::Ingester::API::Representer
  module ItemList
    def self.included(klass)
      klass.include Base
      klass.link :self do |opts|
        "#{opts[:base_url]}/#{represented.id}"
      end
    end

  end
end