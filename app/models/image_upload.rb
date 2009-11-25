class ImageUpload
  include MongoMapper::Document
  key :_id, String
  key :image, Binary
  key :ext, String
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

  def filename
    @filename ||= begin
      if self.new?
        "default.#{self.ext || self.default_path.split(".").last}"
      else
        "#{self.id}.#{self.ext}"
      end
    end
  end

  protected
  def set_type
    self[:_type] = self.class.name
  end
end
