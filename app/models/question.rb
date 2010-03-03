class Question
  include MongoMapper::Document
  include MongoMapperExt::Filter
  include MongoMapperExt::Slugizer
  include MongoMapperExt::Tags
  include Support::Versioneable

  ensure_index :tags
  ensure_index :language
  ensure_index :title
  ensure_index :body

  key :_id, String
  key :title, String, :required => true
  key :body, String
  slug_key :title, :unique => true
  key :answers_count, Integer, :default => 0, :required => true
  key :views_count, Integer, :default => 0
  key :votes_count, Integer, :default => 0
  key :votes_average, Integer, :default => 0
  key :hotness, Integer, :default => 0
  key :flags_count, Integer, :default => 0
  key :favorites_count, Integer, :default => 0

  key :banned, Boolean, :default => false
  key :answered, Boolean, :default => false
  key :wiki, Boolean, :default => false
  key :language, String, :default => "en"

  key :activity_at, Time

  key :user_id, String, :index => true
  belongs_to :user

  key :answer_id, String
  belongs_to :answer

  key :group_id, String, :index => true
  belongs_to :group

  key :watchers, Array

  key :updated_by_id, String
  belongs_to :updated_by, :class_name => "User"

  has_many :answers, :dependent => :destroy
  has_many :votes, :as => "voteable", :dependent => :destroy
  has_many :flags, :as => "flaggeable", :dependent => :destroy
  has_many :badges, :as => "source"
  has_many :comments, :as => "commentable", :dependent => :destroy

  validates_presence_of :user_id
  validates_uniqueness_of :slug, :scope => :group_id

  validates_length_of       :title,    :within => 5..100
  validates_length_of       :body,     :minimum => 5, :allow_blank => true, :allow_nil => true
  validates_true_for :tags, :logic => lambda { !tags.empty? }

  versioneable_keys :title, :body, :tags
  filterable_keys :title, :body
  language :language

  before_save :update_activity_at
  before_validation_on_create :update_language

  validates_inclusion_of :language, :within => AVAILABLE_LANGUAGES
  validates_true_for :language, :logic => lambda { |q| q.group.language == q.language },
                                :if => lambda { |q| !q.group.language.nil? }
  validate :disallow_spam
  validate :check_useful

  timestamps!

  def tags=(t)
    if t.kind_of?(String)
      t = t.downcase.split(",").join(" ").split(" ")
    end
    t = t.collect do |tag|
      tag.gsub("#", "sharp").gsub(".", "dot").gsub("www", "w3")
    end
    self[:tags] = t
  end

  def self.related_questions(question, opts = {})
    opts[:per_page] ||= 10
    opts[:page]     ||= 1
    opts[:group_id] = question.group_id

    Question.paginate(opts.merge(:_keywords => {:$in => question.tags}, :_id => {:$ne => question.id}))
  end

  def viewed!
    self.collection.update({:_id => self._id}, {:$inc => {:views_count => 1}},
                                              :upsert => true)
  end

  def answer_added!
    self.collection.update({:_id => self._id}, {:$inc => {:answers_count => 1}},
                                              :upsert => true)
    on_activity
  end

  def answer_removed!
    self.collection.update({:_id => self._id}, {:$inc => {:answers_count => -1}},
                                               :upsert => true)
  end

  def flagged!
    self.collection.update({:_id => self._id}, {:$inc => {:flags_count => 1}},
                                               :upsert => true)
  end

  def add_vote!(v, voter)
    self.collection.update({:_id => self._id}, {:$inc => {:votes_count => 1,
                                                          :votes_average => v}},
                                                         :upsert => true,
                                                         :safe => true)
    if v > 0
      self.user.update_reputation(:question_receives_up_vote, self.group)
      voter.on_activity(:vote_up_question, self.group)
      self.user.upvote!(self.group)
    else
      self.user.update_reputation(:question_receives_down_vote, self.group)
      voter.on_activity(:vote_down_question, self.group)
      self.user.downvote!(self.group)
    end
    on_activity
  end

  def remove_vote!(v, voter)
    self.collection.update({:_id => self._id}, {:$inc => {:votes_count => -1,
                                                          :votes_average => (-v)}},
                                                         :upsert => true,
                                                         :safe => true)

    if v > 0
      self.user.update_reputation(:question_undo_up_vote, self.group)
      voter.on_activity(:undo_vote_up_question, self.group)
      self.user.upvote!(self.group, -1)
    else
      self.user.update_reputation(:question_undo_down_vote, self.group)
      voter.on_activity(:undo_vote_down_question, self.group)
      self.user.downvote!(self.group, -1)
    end
    on_activity
  end

  def add_favorite!(fav, user)
    self.collection.update({:_id => self._id}, {:$inc => {:favorites_count => 1}},
                                                          :upsert => true)
    on_activity
  end


  def remove_favorite!(fav, user)
    self.collection.update({:_id => self._id}, {:$inc => {:favorites_count => -1}},
                                                          :upsert => true)
    on_activity
  end

  def on_activity
    update_activity_at
    self.collection.update({:_id => self._id}, {:$inc => {:hotness => 1}},
                                                         :upsert => true)
  end

  def update_activity_at
    now = Time.now
    if new?
      self.activity_at = now
    else
      self.collection.update({:_id => self._id}, {:$set => {:activity_at => now}},
                                                 :upsert => true)
    end
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

  def favorite_for?(user)
    user.favorite(self)
  end


  def add_watcher(user)
    if !watch_for?(user)
      self.collection.update({:_id => self.id},
                             {:$push => {:watchers => user.id}},
                             :upsert => true);
    end
  end

  def remove_watcher(user)
    if watch_for?(user)
      self.collection.update({:_id => self.id},
                             {:$pull => {:watchers => user._id}},
                             :upsert => true)
    end
  end

  def watch_for?(user)
    watchers.include?(user._id)
  end

  def check_useful
    if !self.title.blank? && (self.title.split.count < 5)
      self.errors.add(:title, I18n.t("questions.model.messages.too_short", :count => 4))
    end

    if !self.body.blank? && (self.body.split.count < 5)
      self.errors.add(:body, I18n.t("questions.model.messages.too_short", :count => 4))
    end
  end

  def disallow_spam
    last_question = Question.first( :user_id => self.user_id,
                                    :group_id => self.group_id,
                                    :order => "created_at desc")

    valid = ((last_question.nil?) || (Time.now - last_question.created_at) > 20)
    if !valid
      self.errors.add(:body, "Your question looks like spam. you need to wait 20 senconds before posting another question.")
    end
  end

  protected
  def update_answer_count
    self.answers_count = self.answers.count
    votes_average = 0
    self.votes.each {|e| votes_average+=e.value }
    self.votes_average = votes_average

    self.votes_count = self.votes.count
  end

  def update_language
    self.language = self.language.split("-").first
  end

end

