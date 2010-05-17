class UsersWidget < Widget
  before_validation_on_create :set_name
  before_validation_on_update :set_name

  def recent_users(group)
    group.users(:order => "created_at desc",
                :per_page => 5,
                :page => 1)
  end

  protected
  def set_name
    self[:name] ||= "users"
  end
end
