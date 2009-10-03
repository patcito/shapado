module OpenIdAuthentication
  class Nonce
    include MongoMapper::Document

    key :timestamp, Integer
    key :server_url, String
    key :salt, String

  end
end
