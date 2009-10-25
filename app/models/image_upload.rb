class ImageUpload
  include MongoMapper::Document
  key :image, Binary
  key :_type, String

  validates_length_of       :raw,       :maximum => 2000000,
                                        :message => "The maximum file size is 2Mb."

  before_create :set_type

  def raw
    logo = ""
    if self.image
      logo = self.image
    else
      logo = File.read(self.default_path)
    end
    logo.to_s
  end

  def default_path
    @default_path ||= RAILS_ROOT+"/public/images/avatar.png"
  end

  protected
  def set_type
    self[:_type] = self.class.name
  end
end
