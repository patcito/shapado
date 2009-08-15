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
  has_many :votes, :as => "voteable", :dependent => :destroy

  validates_presence_of :user_id, :question_id

  searchable_keys :body

  def to_html
    Maruku.new(self.body).to_html
  end
end
