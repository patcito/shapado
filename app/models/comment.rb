
class Comment
  include MongoMapper::Document

  key :body, String, :required => true
  key :language, String, :default => "en"
  key :banned, Boolean, :default => false

  timestamps!

  key :user_id, String, :index => true
  belongs_to :user

  key :commentable_id, String, :required => true
  key :commentable_type, String, :required => true
  belongs_to :commentable, :polymorphic => true


  key :parent_id
  has_many :children, :foreign_key => "parent_id", :class_name => "Comment", :dependent => :destroy

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
