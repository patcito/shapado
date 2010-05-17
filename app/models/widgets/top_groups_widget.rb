class TopGroupsWidget < Widget
  before_validation_on_create :set_name
  before_validation_on_update :set_name

  def top_groups
    Group.all(:limit => 5, :order => "activity_rate desc", :state => "active", :private => false, :isolate => false)
  end

  protected
  def set_name
    self[:name] ||= "top_groups"
  end
end
