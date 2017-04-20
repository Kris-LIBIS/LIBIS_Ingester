require 'libis/ingester/run'
require 'grape/validations'

module Libis::Ingester::API::Validator
  class ItemId < Grape::Validations::Base
    def validate_param!(attr_name, params)
      unless Libis::Ingester::Item.find_by(id: params[attr_name])
        fail Grape::Exceptions::Validation,
             params: [@scope.full_name(attr_name)],
             message: "'#{params[attr_name]}': item could not be found."
      end
    end
  end
end