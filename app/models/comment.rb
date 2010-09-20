
class Comment
  include MongoMapper::Document
  include Support::Voteable

  key :_id, String
  key :_type, String
  key :body, String, :required => true
  key :language, String, :default => "en"
  key :banned, Boolean, :default => false

  timestamps!

  key :user_id, String, :index => true
  belongs_to :user

  key :group_id, String, :index => true
  belongs_to :group

  key :commentable_id, String
  key :commentable_type, String
  belongs_to :commentable, :polymorphic => true

  validates_presence_of :user

  validate :disallow_spam

  def ban
    self.collection.update({:_id => self.id}, {:$set => {:banned => true}})
  end

  def self.ban(ids)
    ids.each do |id|
      self.collection.update({:_id => id}, {:$set => {:banned => true}})
    end
  end

  def can_be_deleted_by?(user)
    ok = (self.user_id == user.id && user.can_delete_own_comments_on?(self.group)) || user.mod_of?(self.group)
    if !ok && user.can_delete_comments_on_own_questions_on?(self.group) && (q = self.find_question)
      ok = (q.user_id == user.id)
    end

    ok
  end

  def find_question
    question = nil
    if self.commentable.kind_of?(Question)
      question = self.commentable
    elsif self.commentable.respond_to?(:question)
      question = self.commentable.question
    end

    question
  end

  def question_id
    question_id = nil

    if self.commentable_type == "Question"
      question_id = self.commentable_id
    elsif self.commentable_type == "Answer"
      question_id = self.commentable.question_id
    elsif self.commentable.respond_to?(:question)
      question_id = self.commentable.question_id
    end

    question_id
  end

  def find_recipient
    if self.commentable.respond_to?(:user)
      self.commentable.user
    end
  end

  protected
  def disallow_spam
    eq_comment = Comment.first({ :body => self.body,
                                  :commentable_id => self.commentable_id
                                })


    valid = (eq_comment.nil? || eq_comment.id == self.id)
    if !valid
      self.errors.add(:body, "Your comment looks like spam.")
    end
  end
end
