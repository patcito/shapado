class Question
  include MongoMapper::Document
  include MongoMapper::Search

  key :title, String, :required => true
  key :body, String, :required => true
  key :answered, Boolean, :default => false

  belongs_to :user

  validates_presence_of :user_id

  searchable_keys :title, :body
end

