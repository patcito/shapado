
class Share
  include MongoMapper::EmbeddedDocument
  key :_id, String
  key :fb_app_id, String
  key :fb_secret_key, String
  key :fb_starts_with, String
  key :fb_end_with, String
  key :fb_question_asked, String
  key :fb_active, Boolean, :default => false
end
