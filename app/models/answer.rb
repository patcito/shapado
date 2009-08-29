class Answer
  include MongoMapper::Document
  include MongoMapper::Search

  key :body, String, :required => true
  key :language, String, :default => "en"
  key :votes_count, Integer, :default => 0
  key :votes_average, Integer, :default => 0

  timestamps!

  key :user_id, String
  belongs_to :user

  key :question_id, String
  belongs_to :question
  has_many :votes, :as => "voteable", :dependent => :destroy

  validates_presence_of :user_id, :question_id

  searchable_keys :body

  def add_vote!(v)
    self.collection.repsert({:_id => self.id}, {:$inc => {:votes_count => 1}})
    self.collection.repsert({:_id => self.id}, {:$inc => {:votes_average => v}})
  end

  def to_html
    Maruku.new(self.body).to_html
  end
end
