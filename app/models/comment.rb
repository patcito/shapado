
class Comment
  include MongoMapper::Document

  key :_id, String
  key :body, String, :required => true
  key :language, String, :default => "en"
  key :banned, Boolean, :default => false

  timestamps!

  key :user_id, String, :index => true
  belongs_to :user

  key :commentable_id, String
  key :commentable_type, String
  belongs_to :commentable, :polymorphic => true

  validates_presence_of :user

  validate :disallow_spam

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

  def disallow_spam
    eq_comment = Comment.find(:first, { :limit => 1,
                                          :body => self.body,
                                          :commentable_id => self.commentable_id
                                        })


    valid = (eq_comment.nil? || eq_comment.id == self.id)
    if !valid
      self.errors.add(:body, "Your comment looks like spam.")
    end
  end
end
