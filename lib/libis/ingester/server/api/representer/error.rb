module Libis
  module Ingester
    module API
      module Representer

        class Error < Grape::Roar::Decorator
          include Roar::JSON
          include Roar::Coercion
          include Representable::Hash
          include Representable::Hash::AllowSymbols
          include Roar::JSON::JSONAPI::Mixin

          attributes do
            property :status, type: Integer
            property :message, type: String
          end
        end

      end
    end
  end
end
