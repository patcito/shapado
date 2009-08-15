class Vote
  include MongoMapper::Document

  key :value, Integer, :required => true

  key :user_id, String
  belongs_to :user

  key :voteable_id, String
  key :voteable_type, String
  belongs_to :voteable, :polymorphic => true

  validates_presence_of :user_id, :voteable_id
  validates_inclusion_of :value, :within => [1,-1]
end
