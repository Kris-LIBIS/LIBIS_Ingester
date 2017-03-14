require 'roar/coercion'

module Libis::Ingester::API::Representer
  module Base

    def self.included(klass)
      klass.include Roar::JSON
      klass.include Roar::Coercion
      klass.include Representable::Hash
      klass.include Representable::Hash::AllowSymbols
      klass.include Roar::JSON::JSONAPI::Mixin
      klass.property :id, writable: false, render_filter: ->(input, _) { input.to_s },
                     type: String, desc: 'Object\'s unique identifier'
    end


  end

end