
class GroupMember
  include MongoMapper::Document
  timestamps!
  key :group_id, String
  belongs_to :group, :class_name => "Group"
  key :user_id, String
  belongs_to :user, :class_name => "User"

  ROLES = %w[user moderator owner]
  key :role, String, :default => "user"
  validates_inclusion_of :role,  :within => ROLES

  validate :should_be_unique
  protected
  def should_be_unique
    membership = self.class.find(:first, {:limit => 1,
                              :conditions => {
                                :user_id  => self.user_id,
                                :group_id  => self.group_id}
                             })

    valid = (membership.nil? || membership.id == self.id)
    if !valid
      self.errors.add(:member, 'the user already belongs to this group')
    end
  end
end
