class Draft
  include MongoMapper::Document
  timestamps!
  key :_id, String
  key :question, Question
  key :answer, Answer

  def self.cleanup!
    Draft.delete_all(:created_at.lt => 8.days.ago)
  end
end
