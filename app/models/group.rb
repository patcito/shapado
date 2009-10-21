class Group
  include MongoMapper::Document
  include Support::Sluggizer

  slug_key :name
  key :name, String, :required => true
  key :subdomain, String
  key :description, String
  key :categories, Array
  key :logo, Binary

  key :state, String, :default => "pending" #pending, active, closed

  key :owner_id, String
  belongs_to :owner, :class_name => "User"

  validates_length_of       :name,           :within => 3..40
  validates_length_of       :description,    :within => 3..200
  validates_uniqueness_of   :name
  validates_uniqueness_of   :subdomain

  def categories=(c)
    if c.kind_of?(String)
      c = c.downcase.split(",").join(" ").split(" ")
    end
    self[:categories] = c
  end
  alias :user :owner

  def subdomain=(domain)
    self[:subdomain] = domain.gsub(/[^A-Za-z0-9\s\-]/, "")[0,20].
                                                strip.gsub(/\s+/, "-").downcase
  end
end
