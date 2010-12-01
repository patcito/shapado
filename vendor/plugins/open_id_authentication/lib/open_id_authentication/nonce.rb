module OpenIdAuthentication
  class Nonce
    include MongoMapper::Document

    key :_id, String
    key :timestamp, Integer
    key :server_url, String
    key :salt, String

  end
end
