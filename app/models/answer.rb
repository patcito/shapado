class Answer
  include MongoMapper::Document
  include MongoMapper::Search

  key :body, String, :required => true
  key :language, String, :default => "en"

  timestamps!

  key :user_id, String
  belongs_to :user

  key :question_id, String
  belongs_to :question

  validates_presence_of :user_id, :question_id

  searchable_keys :body
end
