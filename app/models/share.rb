class Share
  include MongoMapper::EmbeddedDocument
  key :_id, String
  key :fb_app_id, String
  key :fb_secret_key, String
  key :fb_active, Boolean, :default => false

  key :starts_with, String
  key :ends_with, String

  key :twitter_user, String
end
