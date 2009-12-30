class Badge
  include MongoMapper::Document

  TYPES = %w[gold silver bronce]

  key :_id, String
  key :user_id, String, :required => true
  belongs_to :user

  key :name, String, :required => true
  key :type, String, :required => true

  validates_inclusion_of :type,  :within => TYPES

  def self.gold_badges
    self.find_all_by_type("gold")
  end
end
