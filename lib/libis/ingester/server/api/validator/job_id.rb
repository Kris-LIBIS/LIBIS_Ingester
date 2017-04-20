require 'libis/ingester/job'
require 'grape/validations'

module Libis::Ingester::API::Validator
  class JobId < Grape::Validations::Base
    def validate_param!(attr_name, params)
      unless Libis::Ingester::Job.find_by(id: params[attr_name])
        fail Grape::Exceptions::Validation,
             params: [@scope.full_name(attr_name)],
             message: "'#{params[attr_name]}': job could not be found."
      end
    end
  end
end