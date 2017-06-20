ENV['RACK_ENV'] ||= 'development'
require File.expand_path('../application', __FILE__)

# RSA_PRIVATE = OpenSSL::PKey::RSA.generate 2048
# RSA_PUBLIC = RSA_PRIVATE.public_key
#
# File.open(File.expand_path('../key.priv.pem', __FILE__), 'w') { |f| f.puts(RSA_PRIVATE.to_pem)}
# File.open(File.expand_path('../key.pem', __FILE__), 'w') { |f| f.puts(RSA_PUBLIC.to_pem)}
OpenSSL::PKey::RSA
RSA_PRIVATE = OpenSSL::PKey::RSA.new File.read(File.expand_path('../key.priv.pem', __FILE__))
RSA_PUBLIC = OpenSSL::PKey::RSA.new File.read(File.expand_path('../key.pem', __FILE__))