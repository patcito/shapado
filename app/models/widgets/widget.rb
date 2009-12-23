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
end
