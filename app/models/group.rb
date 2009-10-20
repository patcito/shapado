class Group
  include MongoMapper::Document
  key :name, String
  key :description, String
  key :categories, Array
  key :logo, Binary

  key :state, String, :default => "pending" #pending, active, closed

  key :owner_id, String
  belongs_to :owner, :class_name => "User"

  validates_length_of       :name,           :within => 3..40
  validates_length_of       :description,    :within => 3..200

  def categories=(c)
    if c.kind_of?(String)
      c = c.downcase.split(",").join(" ").split(" ")
    end
    self[:categories] = c
  end
  alias :user :owner
end
