class Ad
  include MongoMapper::Document
  include MongoMapperExt::Slugizer
  POSITIONS=[["context_panel","context_panel"],["header","header"],["footer","footer"],["content","content"]]
  slug_key :name
  key :name
  key :group_id, String
  key :position, String
  key :_type, String
  key :code, String

  belongs_to :group
  before_save :set_code

  before_create :set_type

  def set_code
     self[:code] = self.ad
  end
  validates_presence_of     :position

  def ad
    return
  end

  protected
  def set_type
    self[:_type] = self.class.to_s
  end
end
