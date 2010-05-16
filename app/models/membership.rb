class Membership
  include MongoMapper::EmbeddedDocument

  ROLES = %w[user moderator owner]

  key :_id, String
  key :display_name, String

  key :group_id, String
  belongs_to :group

  key :reputation, Float, :default => 0.0
  key :profile, Hash # custom user keys

  key :votes_up, Float, :default => 0.0
  key :votes_down, Float, :default => 0.0

  key :views_count, Float, :default => 0.0

  key :preferred_tags, Array

  key :last_activity_at, Time
  key :activity_days, Integer, :default => 0

  key :role, String, :default => "user"

  key :bronze_badges_count,       Integer, :default => 0
  key :silver_badges_count,       Integer, :default => 0
  key :gold_badges_count,         Integer, :default => 0
  key :is_editor,                 Boolean, :default => false

  validates_inclusion_of :role,  :within => ROLES
end
