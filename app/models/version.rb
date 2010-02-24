class Version
  include MongoMapper::EmbeddedDocument

  key :_id, String
  key :data, Hash
  key :message, String
  key :date, Time

  key :user_id, String
  belongs_to :user
end
