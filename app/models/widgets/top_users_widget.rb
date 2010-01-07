class TopUsersWidget < Widget
  before_validation_on_create :set_name

  def top_users(group)
    User.all(:order => "reputation.#{group.id} desc",
             :conditions => {:"reputation.#{group.id}" => {:"$exists" => true}},
             :limit => 5)
  end

  protected
  def set_name
    self[:name] ||= "top_users"
  end
end
