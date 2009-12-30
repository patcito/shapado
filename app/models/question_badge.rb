class QuestionBadge < Badge
  key :question_id, :required => true
  belongs_to :question
end
