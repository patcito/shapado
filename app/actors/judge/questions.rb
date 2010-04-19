module JudgeActions
  module Questions
    def on_question_solved(payload)
      question_id, answer_id = payload
      question = Question.find(question_id)
      answer = Answer.find(answer_id)
      group = question.group

      if question.answer == answer && group.answers.count(:user_id => answer.user.id) == 1
        create_badge(answer.user, group, :token => "troubleshooter", :source => answer, :unique => true)
      end

      if question.answer == answer && answer.votes_average >= 10
        create_badge(answer.user, group, {:token => "enlightened", :source => answer}, {:unique => true, :source_id => answer.id})
      end

      if question.answer == answer && answer.votes_average >= 40
        create_badge(answer.user, group, {:token => "guru", :source => answer}, {:unique => true, :source_id => answer.id})
      end

      if question.answer == answer && answer.votes_average > 2
        answer.user.stats.add_expert_tags(*question.tags)
        create_badge(answer.user, group, :token => "tutor", :source => answer, :unique => true)
      end

      if question.user_id == answer.user_id
        create_badge(answer.user, group, :token => "scholar", :source => answer, :unique => true)
      end
    end

    def on_question_unsolved(payload)
      question_id, answer_id = payload
      question = Question.find(question_id)
      answer = Answer.find(answer_id)
      group = question.group

      if answer && question.answer.nil?
        user_badges = answer.user.badges
        badge = user_badges.first(:token => "troubleshooter", :group_id => group.id, :source_id => answer.id)
        badge.destroy if badge

        badge = user_badges.first(:token => "guru", :group_id => group.id, :source_id => answer.id)
        badge.destroy if badge
      end

      if answer && question.answer.nil?
        user_badges = answer.user.badges
        tutor = user_badges.first(:token => "tutor", :group_id => group.id, :source_id => answer.id)
        tutor.destroy if tutor
      end
    end

    def on_view_question(payload)
      question = Question.find!(payload.first)
      user = question.user
      group = question.group

      views = question.views_count
      opts = {:source_id => question.id, :source_type => "Question", :unique => true}
      if views >= 1000
        create_badge(user, group, {:token => "popular_question", :source => question}, opts)
      elsif views >= 2500
        create_badge(user, group, {:token => "notable_question", :source => question}, opts)
      elsif views >= 10000
        create_badge(user, group, {:token => "famous_question", :source => question}, opts)
      end
    end

    def on_ask_question(payload)
      question = Question.find!(payload.first)
      user = question.user
      group = question.group

      if group.questions.count(:user_id => user.id) == 1
        create_badge(user, group, :token => "inquirer", :source => question, :unique => true)
      end
    end

    def on_destroy_question(payload)
      deleter = User.find(payload.first)
      attributes = payload.last
      group = Group.find(attributes["group_id"])

      if deleter.id == attributes["user_id"]
        if attributes["votes_average"] >= 3
          create_badge(deleter, group, :token => "disciplined", :unique => true)
        end

        if attributes["votes_average"] <= -3
          create_badge(deleter, group, :token => "peer_pressure", :unique => true)
        end
      end
    end

    def on_question_favorite(payload)
      question = Question.find(payload.first)
      user = question.user
      group = question.group
      if question.favorites_count >= 25
        create_badge(user, group, {:token => "favorite_question", :source => question}, {:unique => true, :source_id => question.id})
      end

      if question.favorites_count >= 100
        create_badge(user, group, {:token => "stellar_question", :source => question}, {:unique => true, :source_id => question.id})
      end
    end

    def on_retag_question(payload)
      question = Question.find(payload[0])
      user = User.find(payload[1])

      create_badge(user, question.group, {:token => "organizer", :source => question, :unique => true})
    end
  end
end
