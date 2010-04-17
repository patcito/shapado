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
  key :public, Boolean, :default => true

  key :group_id, String, :required => true
  belongs_to :group

  slug_key :title

  file_key :js
  file_key :css
end
