require 'roar/json/json_api'

module Libis::Ingester::API::Representer
  class Base < Grape::Roar::Decorator
    include Roar::JSON
    include Representable::Hash
    include Representable::Hash::AllowSymbols

    include Roar::JSON::JSONAPI::Mixin

    property :id, writable: false, render_filter: ->(input, _) { input.to_s },
             type: 'String', desc: 'Object\'s unique identifier'

  end
end