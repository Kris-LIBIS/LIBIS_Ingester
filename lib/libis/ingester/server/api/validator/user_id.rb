require 'libis/ingester/user'
require 'grape/validations'

module Libis
  module Ingester
    module API
      module Validator
        class UserId < Grape::Validations::Base
          def validate_param!(attr_name, params)
            unless Libis::Ingester::User.find_by(id: params[attr_name])
              fail Grape::Exceptions::Validation,
                   params: [@scope.full_name(attr_name)],
                   message: "Could not find User with id '#{params[attr_name]}'."
            end
          end
        end
      end
    end
  end
end
