class Answer
  include MongoMapper::Document
  include MongoMapper::Search

  key :body, String, :required => true

  belongs_to :user
  belongs_to :question
end
