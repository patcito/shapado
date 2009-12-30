class Answer
  include MongoMapper::Document
  include MongoMapperExt::Filter

  key :body, String, :required => true
  key :language, String, :default => "en"
  key :votes_count, Integer, :default => 0
  key :votes_average, Integer, :default => 0
  key :flags_count, Integer, :default => 0
  key :banned, Boolean, :default => false

  timestamps!

  key :_id, String
  key :user_id, String
  belongs_to :user

  key :question_id, String
  belongs_to :question

  key :group_id, String
  belongs_to :group

  key :parent_id, String
  belongs_to :parent, :class_name => "Answer"

  has_many :children, :foreign_key => "parent_id", :class_name => "Answer", :dependent => :destroy


  has_many :votes, :as => "voteable", :dependent => :destroy
  has_many :flags, :as => "flaggeable", :dependent => :destroy

  validates_presence_of :user_id
  validates_presence_of :question_id, :if => lambda { |e| e.parent_id.blank? }
  validates_presence_of :parent_id, :if => lambda { |e| e.question_id.blank? }

  filterable_keys :body

  validate :disallow_spam
  validate :check_unique_answer

  def check_unique_answer
    check_answer = Answer.find(:first,
                               :question_id => self.question_id,
                               :user_id => self.user_id,
                               :parent_id => nil)

    if !check_answer.nil? && check_answer.id != self.id
      self.errors.add(:limitation, "Your can only post one answer by question.")
      return false
    end
  end

  def add_vote!(v, voter)
    self.collection.update({:_id => self._id}, {:$inc => {:votes_count => 1,
                                                          :votes_average => v}},
                                                         :upsert => true,
                                                         :safe => true)

    if v > 0
      self.user.update_reputation(:answer_receives_up_vote, self.group)
      voter.on_activity(:vote_up_answer, self.group)
      self.user.upvote!
    else
      self.user.update_reputation(:answer_receives_down_vote, self.group)
      voter.on_activity(:vote_down_answer, self.group)
      self.user.downvote!
    end
  end

  def remove_vote!(v, voter)
    self.collection.update({:_id => self._id}, {:$inc => {:votes_count => -1,
                                                          :votes_average => (-v)}},
                                                         :upsert => true,
                                                         :safe => true)

    if v > 0
      self.user.update_reputation(:answer_undo_up_vote, self.group)
      voter.on_activity(:undo_vote_up_answer, self.group)
      self.user.upvote!(-1)
    else
      self.user.update_reputation(:answer_undo_down_vote, self.group)
      voter.on_activity(:undo_vote_down_answer, self.group)
      self.user.downvote!(-1)
    end
  end

  def flagged!
    self.collection.update({:_id => self._id}, {:$inc => {:flags_count => 1}},
                                               :upsert => true)
  end


  def ban
    self.collection.update({:_id => self._id}, {:$set => {:banned => true}},
                                               :upsert => true)
  end

  def self.ban(ids)
    ids = ids.map do |id| id end

    self.collection.update({:_id => {:$in => ids}}, {:$set => {:banned => true}},
                                                     :multi => true,
                                                     :upsert => true)
  end

  def comment?
    !self.parent_id.blank?
  end

  def to_html
    Maruku.new(self.body).to_html
  end

  def disallow_spam
    eq_answer = Answer.find(:first, { :limit => 1,
                                      :body => self.body,
                                      :question_id => self.question_id,
                                      :group_id => self.group_id
                                    })

    last_answer  = Answer.find(:first, :limit => 1,
                                       :user_id => self._id,
                                       :question_id => self.question_id,
                                       :group_id => self.group_id,
                                       :order => "created_at desc")

    valid = (eq_answer.nil? || eq_answer.id == self.id) &&
            ((last_answer.nil?) || (Time.now - last_answer.created_at) > 20)
    if !valid
      self.errors.add(:body, "Your answer looks like spam.")
    end
  end
end
