class Answer < Comment
  include MongoMapper::Document
  include MongoMapperExt::Filter
  key :_id, String

  key :body, String, :required => true
  key :language, String, :default => "en"
  key :votes_count, Integer, :default => 0
  key :votes_average, Integer, :default => 0
  key :flags_count, Integer, :default => 0
  key :banned, Boolean, :default => false
  key :versions, Array
  key :wiki, Boolean, :default => false

  timestamps!

  key :updated_by_id, String
  belongs_to :updated_by, :class_name => "User"

  key :question_id, String
  belongs_to :question

  key :group_id, String, :index => true
  belongs_to :group

  has_many :votes, :as => "voteable", :dependent => :destroy
  has_many :flags, :as => "flaggeable", :dependent => :destroy

  has_many :comments, :foreign_key => "commentable_id", :class_name => "Comment", :dependent => :destroy

  validates_presence_of :user_id
  validates_presence_of :question_id

  filterable_keys :body

  validate :disallow_spam
  validate :check_unique_answer

  before_save :save_version, :if => Proc.new { |d| !d.rolling_back }

  attr_accessor :rolling_back

  def check_unique_answer
    check_answer = Answer.find(:first,
                               :question_id => self.question_id,
                               :user_id => self.user_id)

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
      self.user.upvote!(self.group)
    else
      self.user.update_reputation(:answer_receives_down_vote, self.group)
      voter.on_activity(:vote_down_answer, self.group)
      self.user.downvote!(self.group)
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
      self.user.upvote!(self.group, -1)
    else
      self.user.update_reputation(:answer_undo_down_vote, self.group)
      voter.on_activity(:undo_vote_down_answer, self.group)
      self.user.downvote!(self.group, -1)
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

  def rollback!(pos = nil)
    pos = self.versions.count-1 if pos.nil?
    version = self.versions[pos]

    if version
      self.body = version["body"]
      self.updated_by_id = version["user_id"]
      self.updated_at = version["date"]
    end

    @rolling_back = true
    save!
  end

  protected
  def save_version
    if !self.new? && self.body_changed? && self.updated_by_id
      self.versions << {'body' => self.body_was,
                        'user_id' => (self.updated_by_id_was || self.updated_by_id),
                        'date' => self.updated_at_was.try(:utc) }
    end
  end
end
