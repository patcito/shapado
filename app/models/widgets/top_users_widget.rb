class TopUsersWidget < Widget
  before_validation_on_create :set_name

  def top_users(group)
    group.users(:order => "reputation.#{group.id} desc",
                :per_page => 5,
                :page => 1)
  end

  protected
  def set_name
    self[:name] ||= "top_users"
  end
end
