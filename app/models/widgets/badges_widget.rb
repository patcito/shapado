class BadgesWidget < Widget
  before_validation_on_create :set_name
  before_validation_on_update :set_name

  def recent_badges(group)
    group.badges.all(:limit => 5, :order => "created_at desc")
  end


  protected
  def set_name
    self[:name] ||= "badges"
  end
end
