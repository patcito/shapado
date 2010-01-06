class BadgesWidget < Widget
  before_validation_on_create :set_name

  def recent_badges(group)
    group.badges.find(:all, :limit => 5, :order => "created_at desc")
  end

  def description
    "This widget display recent Badges earned by users or questions"
  end

  protected
  def set_name
    self[:name] ||= "badges"
  end
end
