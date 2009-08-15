class Question
  include MongoMapper::Document
  include MongoMapper::Search

  key :title, String, :required => true
  key :body, String, :required => true
  key :slug, String, :required => true

  key :answered, Boolean, :default => false
  key :language, String, :default => "en"

  belongs_to :user
  has_many :answers, :dependent => :destroy

  validates_presence_of :user_id

  searchable_keys :title, :body

  before_validation_on_create :sluggize

  def to_param
    self.slug || self.id
  end

  def self.find_by_slug_or_id(id)
    self.find_by_slug(id) || self.find_by_id(id)
  end

  protected
  def sluggize
    if self.slug.blank?
      self.slug = self.title.gsub(/[^A-Za-z0-9\s\-]/, "")[0,40].strip.gsub(/\s+/, "-")
    end
  end
end

