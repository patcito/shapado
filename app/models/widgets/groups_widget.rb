class GroupsWidget < Widget
  before_validation_on_create :set_name

  def recent_groups
    Group.all(:limit => 5, :order => "created_at desc", :state => "active")
  end


  protected
  def set_name
    self[:name] ||= "groups"
  end
end
