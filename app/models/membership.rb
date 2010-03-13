class Membership
  include MongoMapper::Document
  ROLES = %w[user moderator owner]

  key :_id, String
  key :display_name, String

  key :group_id, String
  belongs_to :group

  key :reputation, Float, :default => 0.0
  key :profile, Hash # custom user keys

  key :votes_up, Float, :default => 0.0
  key :votes_down, Float, :default => 0.0

  key :followers_count, Integer, :default => 0
  key :following_count, Integer, :default => 0
  key :preferred_tags, Array

  key :last_activity_at, Time
  key :activity_days, Time

  key :role, String, :default => "user"


  validates_inclusion_of :role,  :within => ROLES
end
