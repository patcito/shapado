class TagCloudWidget < Widget
  before_validation_on_create :set_name

  protected
  def set_name
    self[:name] ||= "tag_cloud"
  end
end