require File.dirname(__FILE__)+"/env"

module Actors
  # /actors/judge
  class Judge
    include Magent::Actor

    expose :on_question_solved
    expose :on_question_unsolved

    def on_question_solved(payload)
      question_id, answer_id = payload
      question = Question.find(question_id)
      answer = Answer.find(answer_id)

      if question.answer == answer && answer.votes_average > 2
        user_badges = answer.user.badges
        user_badges.find_by_token("tutor") || user_badges.create!(:token => "tutor", :type => "bronze", :source => answer)
      end
    end

    def on_question_unsolved(payload)
      question_id, answer_id = payload
      question = Question.find(question_id)
      answer = Answer.find(answer_id)

      if answer && question.answer.nil?
        user_badges = answer.user.badges
        tutor = user_badges.find(:first, :token => "tutor", :source_id => answer.id)
        tutor.destroy if tutor
      end
    end
  end
  Magent.register(Judge.new)
end

if $0 == __FILE__
  Magent::Processor.new(Magent.current_actor).run!
end
