require 'jwt'

module Libis::Ingester::API::TokenHelper
  extend Grape::API::Helpers

  ISSUER='Teneo App'.freeze

  def jwt_encode(payload)
    data = payload.merge(
        iat: Time.now.to_i,
        exp: Time.now.to_i + 4 * 3600,
        iss: ISSUER
    )
    result = JWT.encode(data, RSA_PRIVATE, 'RS256')
    result
  end

  def jwt_decode(token)
    payload = JWT.decode(token, RSA_PUBLIC, true,
                         {algorithm: 'RS256', iss: ISSUER, verify_iss: true, verify_iat: true}).first
    payload.reject {|k, _| %w'iat exp iss'.include? k}
  rescue JWT::DecodeError => e
    api_error(401, e.message)
  rescue Exception => e
    api_error(401, e.message)
  end

  def jwt_refresh(token)
    payload = jwt_decode(token)
    jwt_encode(payload)
  end

end
