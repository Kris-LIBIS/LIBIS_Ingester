require 'jwt'

module Libis::Ingester::API::TokenHelper
  extend Grape::API::Helpers

  RSA_PRIVATE = OpenSSL::PKey::RSA.generate 2048
  RSA_PUBLIC = RSA_PRIVATE.public_key

  ISSUER='Teneo App'.freeze

  def jwt_encode(payload)
    data = payload.merge(
        iat: Time.now.to_i,
        exp: Time.now.to_i + 4 * 3600,
        iss: ISSUER
    )
    JWT.encode(data, RSA_PUBLIC, 'RS256')
  end

  def jwt_decode(token)
    payload = JWT.decode(token, RSA_PRIVATE, true, {algorithm: 'HS256', iss: ISSUER, verify_iss: true}).first
    payload.reject {|k, _| %w'iat exp iss'.include? k}
  rescue JWT::ExpiredSignature
    api_error(401, 'Token expired')
  rescue JWT::InvalidIssuerError
    api_error(401, 'Invalid JWT token')
  end

  def jwt_refresh(token)
    payload = jwt_decode(token)
    jwt_encode(payload)
  end

end
