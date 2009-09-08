class Answer
  include MongoMapper::Document
  include MongoMapper::Search

  key :body, String, :required => true
  key :language, String, :default => "en"
  key :votes_count, Integer, :default => 0
  key :votes_average, Integer, :default => 0
  key :flags_count, Integer, :default => 0
  key :banned, Boolean, :default => false

  timestamps!

  key :user_id, String
  belongs_to :user

  key :parent_id, String
  belongs_to :parent, :class_name => "Answer"

  has_many :children, :foreign_key => "parent_id", :class_name => "Answer", :dependent => :destroy

  key :question_id, String
  belongs_to :question
  has_many :votes, :as => "voteable", :dependent => :destroy
  has_many :flags, :as => "flaggeable", :dependent => :destroy

  validates_presence_of :user_id
  validates_presence_of :question_id, :if => lambda { |e| e.parent_id.blank? }
  validates_presence_of :parent_id, :if => lambda { |e| e.question_id.blank? }

  searchable_keys :body

  validate :disallow_span

  def add_vote!(v, voter)
    self.collection.update({:_id => self.id}, {:$inc => {:votes_count => 1}},
                                                         :upsert => true)
    self.collection.update({:_id => self.id}, {:$inc => {:votes_average => v}},
                                                         :upsert => true)
    if v > 0
      self.user.update_reputation(:answer_receives_up_vote)
      voter.update_reputation(:vote_up_answer)
    else
      self.user.update_reputation(:answer_receives_down_vote)
      voter.update_reputation(:vote_down_answer)
    end
  end

  def flagged!
    self.collection.update({:_id => self.id}, {:$inc => {:flags_count => 1}},
                                               :upsert => true)
  end


  def ban
    self.collection.update({:_id => self.id}, {:$set => {:banned => true}},
                                               :upsert => true)
  end

  def self.ban(ids)
    ids.each do |id|
      self.collection.update({:_id => id}, {:$set => {:banned => true}},
                                                       :upsert => true)
    end
  end

  def comment?
    !self.parent_id.blank?
  end

  def to_html
    Maruku.new(self.body).to_html
  end

  def disallow_span
    eq_answer = Answer.find(:first, {:limit => 1,
                              :conditions => {
                                :body => self.body,
                                :question_id => self.question_id
                               }})

    last_answer  = Answer.find(:first, {:limit => 1,
                               :conditions => {
                                 :user_id => self.id,
                                 :question_id => question.id
                               },
                               :order => "created_at desc"})

    valid = (eq_answer.nil? || eq_answer.id == self.id) &&
            (last_answer.nil? || (Time.now - last_answer.created_at) > 20)
    if !valid
      self.errors.add(:body, "Your answer looks like spam.")
    end
  end
end
