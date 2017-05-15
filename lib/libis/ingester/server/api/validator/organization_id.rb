require 'libis/ingester/organization'
require 'grape/validations'

module Libis::Ingester::API::Validator
  class OrganizationId < Grape::Validations::Base
    def validate_param!(attr_name, params)
      unless Libis::Ingester::Organization.find_by(id: params[attr_name])
        fail Grape::Exceptions::Validation,
             params: [@scope.full_name(attr_name)],
             message: "'#{params[attr_name]}': organization could not be found."
      end
    end
  end
end

module Libis::Ingester::API::Validator
  class OrganizationIds < Grape::Validations::Base
    def validate_param!(attr_name, params)
      params[attr_name].each do |id|
        unless Libis::Ingester::Organization.find_by(id: id)
          fail Grape::Exceptions::Validation,
               params: [@scope.full_name(attr_name)],
               message: "'#{id}': organization could not be found."
        end
      end
    end
  end
end