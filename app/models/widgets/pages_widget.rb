class PagesWidget < Widget
  before_validation_on_create :set_name
  before_validation_on_update :set_name

  def recent_pages(group)
    group.pages.paginate(:order => "created_at desc",
                         :per_page => 5,
                         :page => 1,
                         :wiki => true)
  end

  protected
  def set_name
    self[:name] ||= "pages"
  end
end
