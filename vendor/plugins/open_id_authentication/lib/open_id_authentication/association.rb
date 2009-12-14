module OpenIdAuthentication
  class Association
    include MongoMapper::Document

    key :issued, Integer
    key :lifetime, Integer
    key :handle, String
    key :assoc_type, String
    key :server_url, Binary ## FIXME may needs binary?
    key :secret, Binary ## FIXME may needs binary?


    def from_record
      OpenID::Association.new(handle, secret, issued, lifetime, assoc_type)
    end
  end
end
