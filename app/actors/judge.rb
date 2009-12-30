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

      $stderr.puts "#{question.inspect} #{answer.inspect}"
    end

    def on_question_unsolved(payload)
      question_id, answer_id = payload
      question = Question.find(question_id)
      answer = Answer.find(answer_id)

      $stderr.puts "#{question.inspect} #{answer.inspect}"
    end
  end
  Magent.register(Judge.new)
end

if $0 == __FILE__
  Magent::Processor.new(Magent.current_actor).run!
end
