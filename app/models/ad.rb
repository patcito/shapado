class Ad
  include MongoMapper::Document
  include Support::Sluggizer
  POSITIONS=[["context_panel","context_panel"],["header","header"],["footer","footer"],["content","content"]]
  slug_key :name
  key :name
  key :group_id, ObjectId
  key :position, String
  key :_type, String
  key :code, String

  belongs_to :group
  before_save :set_code

  def set_code
     self[:code] = self.ad
  end
  validates_presence_of     :position

  def ad
    return
  end
end