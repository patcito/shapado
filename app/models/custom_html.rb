class CustomHtml
  include MongoMapper::EmbeddedDocument

  key :_id, String
  key :top_bar, String, :default => "[[faq|FAQ]]"
end
