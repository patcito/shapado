class Question
  include MongoMapper::Document
  include MongoMapper::Search

  key :title, String, :required => true
  key :body, String, :required => true
  key :answered, Boolean, :default => false
  key :language, String, :default => "en"

  belongs_to :user
  has_many :answers, :dependent => :destroy

  validates_presence_of :user_id

  searchable_keys :title, :body
end

