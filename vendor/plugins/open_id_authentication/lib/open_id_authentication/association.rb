module OpenIdAuthentication
  class Association
    include MongoMapper::Document

    key :_id, String
    key :issued, Integer
    key :lifetime, Integer
    key :handle, String
    key :assoc_type, String
    key :server_url, String ## FIXME may needs binary?
#     key :secret, Binary ## FIXME may needs binary?
    key :secret_data, Binary


    def secret
      self.secret_data.to_s
    end

    def secret=(data)
      self.secret_data = data
    end

    def from_record
      OpenID::Association.new(handle, secret, issued, lifetime, assoc_type)
    end
  end
end
