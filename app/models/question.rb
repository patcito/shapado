class Question
  include MongoMapper::Document
  include MongoMapper::Search

  ensure_index :slug
  ensure_index :tags
  ensure_index :language

  key :title, String, :required => true
  key :body, String, :required => true
  key :slug, String, :required => true
  key :answers_count, Integer, :default => 0, :required => true
  key :views_count, Integer, :default => 0
  key :votes_count, Integer, :default => 0
  key :votes_average, Integer, :default => 0

  key :answered, Boolean, :default => false
  key :language, String, :default => "en"

  key :tags, Array, :default => []
  key :_metatags, Array, :default => []
  key :category, String

  key :user_id, String
  belongs_to :user

  key :answer_id, String
  belongs_to :answer
  has_many :answers, :dependent => :destroy
  has_many :votes, :as => "voteable", :dependent => :destroy

  validates_presence_of :user_id
  validates_uniqueness_of :slug

  searchable_keys :title, :body

  before_save :update_metatags
  before_validation_on_create :sluggize, :update_language
  before_validation_on_update :update_answer_count

  validates_inclusion_of :category, :within => Shapado::CATEGORIES
  validates_inclusion_of :language, :within => AVAILABLE_LANGUAGES
  timestamps!

  def to_param
    self.slug || self.id
  end

  def self.find_by_slug_or_id(id)
    self.find_by_slug(id) || self.find_by_id(id)
  end

  def tags=(t)
    if t.kind_of?(String)
      t = t.downcase.split(",").join(" ").split(" ")
    end
    self[:tags] = t
  end

  def self.tag_cloud(conditions = {})
    @tag_cloud_code ||= RAILS_ROOT + "/app/javascripts/tag_cloud.js"
    self.database.eval(File.read(@tag_cloud_code), conditions)
  end

  def viewed!
    self.collection.repsert({:_id => self.id}, {:$inc => {:views_count => 1}})
  end

  def answer_added!
    self.collection.repsert({:_id => self.id}, {:$inc => {:answers_count => 1}})
  end

  def answer_removed!
    self.collection.repsert({:_id => self.id}, {:$inc => {:answers_count => -1}})
  end

  protected
  def update_metatags
    self._metatags = []
    self._metatags << self.language
    self._metatags << self.category
    self._metatags += self.tags
  end

  def sluggize
    if self.slug.blank?
      self.slug = self.title.gsub(/[^A-Za-z0-9\s\-]/, "")[0,40].strip.gsub(/\s+/, "-").downcase
    end
  end

  def update_answer_count
    self.answers_count = self.answers.count
    votes_average = 0
    self.votes.each {|e| votes_average+=e.value }
    self.votes_average = votes_average

    self.votes_count = self.votes.count
  end

  def update_language
    self.language = self.language.split("-").first
  end
end

