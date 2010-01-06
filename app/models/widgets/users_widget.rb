class UsersWidget < Widget
  before_validation_on_create :set_name

  def recent_users(group)
    User.all(:order => "created_at desc",
             :conditions => {:"reputation.#{group.id}" => {:"$exists" => true}},
             :limit => 5)
  end

  def description
    "This widget display new registered members"
  end

  protected
  def set_name
    self[:name] ||= "users"
  end
end
