module Libis
  module Ingester
    module API
      module Representer

        class Status < Grape::Roar::Decorator
          include Roar::JSON
          include Roar::Coercion
          include Representable::Hash
          include Representable::Hash::AllowSymbols
          include Roar::JSON::JSONAPI::Mixin

          type :status
          property :id, type: String

          attributes do
            property :error, type: String
            property :message, type: String
          end

          def id
            nil
          end

        end

      end
    end
  end
end
