class Widget
  include MongoMapper::Document

  key :_id, String

  key :name, String, :required => true, :index => true
  key :position, Integer, :default => 0

  key :_type, String
  key :group_id, String
  belongs_to :group

  validates_uniqueness_of :name, :scope => :group_id

  def partial_name
    "widgets/#{self.name}"
  end

  def up
    self.move_to(self.position-1)
  end

  def down
    self.move_to(self.position+1)
  end

  def move_to(pos)
    widget = Widget.find(:first, :position => pos.to_i, :group_id => self.group_id)
    if widget
      self.collection.update({:_id => widget._id}, {:$set => {:position => self.position}},
                                                               :upsert => true)
      self.collection.update({:_id => self._id}, {:$set => {:position => widget.position}},
                                                               :upsert => true)
    end
  end
end
