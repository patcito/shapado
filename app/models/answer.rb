class Answer
  include MongoMapper::Document
  include MongoMapper::Search

  key :body, String, :required => true
  key :language, String, :default => "en"

  belongs_to :user
  belongs_to :question

  validates_presence_of :user_id, :question_id

  searchable_keys :body
end
