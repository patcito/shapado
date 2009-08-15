class Vote
  include MongoMapper::Document

  key :value, Boolean, :required => true

  belongs_to :user
  belongs_to :voteable, :polymorphic => true

  validates_presence_of :user_id, :voteable_id
  validates_inclusion_of :value, :within => [1,-1]
end
