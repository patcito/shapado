class Question
  include MongoMapper::Document

  key :title, String
  key :body, String
  key :answered, Boolean

  belongs_to :user

  validates_presence_of :user_id, :body, :title
end

