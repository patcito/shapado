class Share
  include MongoMapper::EmbeddedDocument
  key :_id, String
  key :fb_app_id, String
  key :fb_secret_key, String
  key :fb_active, Boolean, :default => false

  key :starts_with, String
  key :ends_with, String

  key :enable_twitter, Boolean, :default => false
  key :twitter_user, String
  key :twitter_pattern, String
end
