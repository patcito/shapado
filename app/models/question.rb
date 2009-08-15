class Question
  include MongoMapper::Document

  key :title, String, :required => true
  key :body, String, :required => true
  key :answered, Boolean, :default => false

  belongs_to :user

  validates_presence_of :user_id
end

