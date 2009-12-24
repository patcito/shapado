class Draft
  include MongoMapper::Document
  key :_id, String
  key :question, Question
  key :answer, Answer
end
