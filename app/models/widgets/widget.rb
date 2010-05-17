class Widget
  include MongoMapper::EmbeddedDocument

  key :_id, String
  key :name, String, :required => true
  key :_type, String

  alias :group :_root_document

  def self.types
    types = %w[UsersWidget BadgesWidget TopUsersWidget TagCloudWidget PagesWidget]
    if AppConfig.enable_groups
      types += %w[GroupsWidget TopGroupsWidget]
    end

    types
  end

  def partial_name
    "widgets/#{self.name}"
  end

  def up
    self.move_to("up")
  end

  def down
    self.move_to("down")
  end

  def move_to(pos)
    pos ||= "up"
    widgets = group.widgets
    current_pos = widgets.index(self)
    if pos == "up"
      pos = current_pos-1
    elsif pos == "down"
      pos = current_pos+1
    end

    if pos >= widgets.size
      pos = 0
    elsif pos < 0
      pos = widgets.size-1
    end

    widgets[current_pos], widgets[pos] = widgets[pos], widgets[current_pos]
    group.widgets = widgets
    group.save
  end

  def description
    @description ||= I18n.t("widgets.#{self.name}.description") if self.name
  end
end

