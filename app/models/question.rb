class Question
  include CouchMapper::Document

  key :title, String
  key :body, String
  key :answered, Boolean

  belongs_to :user
end
