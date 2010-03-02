
class Member
  include MongoMapper::Document
  timestamps!
  key :_id, String
  key :group_id, String
  belongs_to :group, :class_name => "Group"
  key :user_id, String
  belongs_to :user, :class_name => "User"

  ROLES = %w[user moderator owner]
  key :role, String, :default => "user"
  validates_inclusion_of :role,  :within => ROLES

  validate_on_update :ensure_user_owners_on_update
  before_destroy :ensure_user_owners_on_destroy
  validate :should_be_unique



  protected
  def should_be_unique
    membership = self.class.first( :user_id  => self.user_id,
                                   :group_id  => self.group_id)

    valid = (membership.nil? || membership.id == self.id)
    if !valid
      self.errors.add(:member, 'the user already belongs to this group')
      return false
    end
  end

  def ensure_user_owners_on_update
    changes = self.changes["role"]
    if changes && changes.first == "owner" && (changes.last != "owner")
      if(self.group.memberships(:role => "owner").count < 2)
        self.errors.add(:owners, 'must exists unless a group owner')
        return false
      end
    end
  end

  def ensure_user_owners_on_destroy
    if(self.role == "owner" && self.group.memberships(:role => "owner").count < 2)
      self.errors.add(:owners, 'must exists unless a group owner')
      return false
    end
  end
end
