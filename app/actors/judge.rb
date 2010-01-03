require File.dirname(__FILE__)+"/env"

module Actors
  # /actors/judge
  class Judge
    include Magent::Actor

    expose :on_question_solved
    def on_question_solved(payload)
      question_id, answer_id = payload
      question = Question.find(question_id)
      answer = Answer.find(answer_id)

      if question.answer == answer && answer.user.answers.count == 1
        user_badges = answer.user.badges
        user_badges.find_by_token("troubleshooter") || user_badges.create!(:token => "troubleshooter", :type => "bronze", :source => answer)
      end

      if question.answer == answer && answer.votes_average > 2
        user_badges = answer.user.badges
        user_badges.find_by_token("tutor") || user_badges.create!(:token => "tutor", :type => "bronze", :source => answer)
      end
    end

    expose :on_question_unsolved
    def on_question_unsolved(payload)
      question_id, answer_id = payload
      question = Question.find(question_id)
      answer = Answer.find(answer_id)

      if answer && question.answer.nil?
        user_badges = answer.user.badges
        badge = user_badges.find(:first, :token => "troubleshooter", :source_id => answer.id)
        badge.destroy if badge
      end

      if answer && question.answer.nil?
        user_badges = answer.user.badges
        tutor = user_badges.find(:first, :token => "tutor", :source_id => answer.id)
        tutor.destroy if tutor
      end
    end

    expose :on_ask_question
    def on_ask_question(payload)
      question = Question.find(payload.first)
      user = question.user

      if user.questions.count == 1
        user_badges = user.badges
        user_badges.find_by_token("inquirer") || user_badges.create!(:token => "inquirer", :type => "bronze", :source => question)
      end
    end

    expose :on_destroy_question
    def on_destroy_question(payload)
      user = User.find(payload.first)
      if user.questions.first.nil?
        user_badges = user.badges
        inquirer = user_badges.find(:first, :token => "inquirer")
        inquirer.destroy if inquirer
      end
    end

    expose :on_vote
    def on_vote(payload)
      vote = Vote.find(payload.first)
      user = vote.user
      if user.votes.count == 1 && vote.value == -1
        user_badges = user.badges
        user_badges.find_by_token("critic") || user_badges.create!(:token => "critic", :type => "bronze", :source => vote)
      end
    end
  end
  Magent.register(Judge.new)
end

if $0 == __FILE__
  Magent::Processor.new(Magent.current_actor).run!
end
