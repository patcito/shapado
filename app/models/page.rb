class Page
  include MongoMapper::Document
  include MongoMapperExt::Filter
  include MongoMapperExt::Slugizer
  include MongoMapperExt::Tags
  include MongoMapperExt::Storage
  include Support::Versionable

  key :_id, String
  key :title, String
  key :body, String
  key :wiki, Boolean, :default => false
  key :language, String
  key :adult_content, Boolean, :default => false

  key :user_id, String
  belongs_to :user

  key :group_id, String, :required => true
  belongs_to :group

  key :updated_by_id, String
  belongs_to :updated_by, :class_name => "User"

  slug_key :title, :unique => true, :min_length => 3

  file_key :js
  file_key :css

  versionable_keys :title, :body, :tags

  validates_uniqueness_of :title, :scope => [:group_id, :language]
  validates_uniqueness_of :slug, :scope => [:group_id, :language], :allow_blank => true

  def self.by_title(title, options)
    self.first(options.merge(:title => title, :language => I18n.locale)) || self.first(options.merge(:title => title)) || self.by_slug(title, options, :language => I18n.locale) || self.by_slug(title, options)
  end
end
