class Flag
  include MongoMapper::Document
  TYPES = ["spam", "attention", "offensive"]
  key :type, String, :required => true

  key :user_id, String
  belongs_to :user

  key :flaggeable_id, String
  key :flaggeable_type, String
  belongs_to :flaggeable, :polymorphic => true

  validates_presence_of :user_id, :flaggeable_id, :flaggeable_type
  validates_inclusion_of :type, :within => TYPES

  validate :should_be_unique

  protected
  def should_be_unique
    flag = Flag.find(:first, {:limit => 1,
                              :conditions => {
                                :flaggeable_type => self.flaggeable_type,
                                :flaggeable_id => self.flaggeable_id,
                                :user_id     => self.user_id}
                             })

    valid = (flag.nil? || flag.id == self.id)
    if !valid
      self.errors.add(:flagged, "You already flaged this #{self.flaggeable_type}")
    end
  end
end
