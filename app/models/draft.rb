class Draft
  include MongoMapper::Document
  timestamps!
  key :_id, String
  key :question, Question
  key :answer, Answer
end
