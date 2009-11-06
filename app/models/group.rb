class Group
  include MongoMapper::Document
  include Support::Sluggizer

  slug_key :name
  key :name, String, :required => true
  key :subdomain, String
  key :legend, String
  key :description, String
  key :categories, Array

  key :state, String, :default => "pending" #pending, active, closed

  key :owner_id, String
  belongs_to :owner, :class_name => "User"

  validates_length_of       :name,           :within => 3..40
  validates_length_of       :description,    :within => 3..400
  validates_length_of       :legend,         :maximum => 40
  validates_uniqueness_of   :name
  validates_uniqueness_of   :subdomain
  validates_presence_of     :subdomain
  validates_format_of       :subdomain, :with => /^[a-z0-9\-]+$/i
  validates_length_of       :subdomain, :within => 3..32

  def categories=(c)
    if c.kind_of?(String)
      c = c.downcase.split(",").join(" ").split(" ")
    end
    self[:categories] = c
  end
  alias :user :owner

  def logo_data=(data)
    logo = self.logo
    if data.respond_to?(:read)
      logo.image = data.read
      ext = data.original_filename.split(".").last
      logo.ext = ext if ext
    elsif data.kind_of?(String)
      logo.image = File.read(data)
      ext = data.split(".").last
      logo.ext = ext if ext
    end
    logo.group = self

    logo.save
  end

  def logo
    @logo ||= (Logo.find(:first, :group_id => self.id) || Logo.new)
  end

end

