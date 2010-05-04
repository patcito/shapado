class Widget
  include MongoMapper::Document

  key :_id, String

  key :name, String, :required => true, :index => true
  key :position, Integer, :default => 0

  key :_type, String
  key :group_id, String, :index => true
  belongs_to :group

  validates_uniqueness_of :name, :scope => :group_id

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
    scope = {:group_id => self.group_id}
    widget = nil
    if pos == "up"
      widget = Widget.first(scope.merge(:position => {:$lt => self.position}))
    elsif pos == "down"
      widget = Widget.first(scope.merge(:position => {:$gt => self.position}))
    else
      if pos.to_i > self.position
        widget = Widget.first(scope.merge(:position => {:$gt => self.position}))
      else
        widget = Widget.first(scope.merge(:position => {:$lt => self.position}))
      end
    end

    if widget
      self.collection.update({:_id => widget._id}, {:$set => {:position => self.position}},
                                                               :upsert => true)
      self.collection.update({:_id => self._id}, {:$set => {:position => widget.position}},
                                                               :upsert => true)
    end
  end

  def description
    @description ||= I18n.t("widgets.#{self.name}.description") if self.name
  end
end

