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
      group = question.group

      if question.answer == answer && group.answers.count(:user_id => answer.user.id) == 1
        user_badges = answer.user.badges
        answer.user.find_badge_on(group,"troubleshooter") || user_badges.create!(:token => "troubleshooter", :type => "bronze", :group => group, :source => answer)
      end

      if question.answer == answer && answer.votes_average >= 40
        answer.user.find_badge_on(group,"guru") || user_badges.create!(:token => "guru", :type => "silver", :group => group, :source => answer)
      end

      if question.answer == answer && answer.votes_average > 2
        user_badges = answer.user.badges
        answer.user.find_badge_on(group,"tutor") || user_badges.create!(:token => "tutor", :type => "bronze", :group => group, :source => answer)
      end

      answer.user.stats.add_expert_tags(*question.tags)
    end

    expose :on_question_unsolved
    def on_question_unsolved(payload)
      question_id, answer_id = payload
      question = Question.find(question_id)
      answer = Answer.find(answer_id)
      group = question.group

      if answer && question.answer.nil?
        user_badges = answer.user.badges
        badge = user_badges.find(:first, :token => "troubleshooter", :group_id => group.id, :source_id => answer.id)
        badge.destroy if badge

        badge = user_badges.find(:first, :token => "guru", :group_id => group.id, :source_id => answer.id)
        badge.destroy if badge
      end

      if answer && question.answer.nil?
        user_badges = answer.user.badges
        tutor = user_badges.find(:first, :token => "tutor", :group_id => group.id, :source_id => answer.id)
        tutor.destroy if tutor
      end
    end

    expose :on_ask_question
    def on_ask_question(payload)
      question = Question.find(payload.first)
      user = question.user
      group = question.group

      if group.questions.count(:user_id => user.id) == 1
        user_badges = user.badges
        user.find_badge_on(group, "inquirer") || user_badges.create!(:token => "inquirer", :type => "bronze", :group_id => group.id, :source => question)
      end
    end

    expose :on_destroy_question
    def on_destroy_question(payload)
      user = User.find(payload.first) # FIXME: pass the group id
      if user.questions.first.nil?
        user_badges = user.badges
        user_badges.destroy_all(:token => "inquirer")
      end
    end

    expose :on_vote
    def on_vote(payload)
      vote = Vote.find(payload.first)
      user = vote.user
      voteable = vote.voteable
      group = vote.group

      if vote.value == -1
        user_badges = user.badges
        user.find_badge_on(group,"critic") || user_badges.create!(:token => "critic", :type => "bronze", :group_id => group.id, :source => vote)
      else
        user_badges = user.badges
        user.find_badge_on(group,"supporter") || user_badges.create!(:token => "supporter", :type => "bronze", :group_id => group.id, :source => vote)
      end

      if user.stats(:views_count).views_count >= 10000
        user.find_badge_on(group,"popular_person") || user.badges.create!(:token => "popular_person", :type => "silver", :group_id => group.id)
      end

      # users
      if vuser = voteable.user
        user_badges = vuser.badges
        vote_value = vuser.votes_up[group.id] ? vuser.votes_up[group.id] : 0

        if vote_value >= 100
          vuser.find_badge_on(group,"effort_medal") || user_badges.create!(:token => "effort_medal", :type => "silver", :group_id => group.id, :source => vote)
        end

        if vote_value >= 200
          vuser.find_badge_on(group,"merit_medal") || user_badges.create!(:token => "merit_medal", :type => "silver", :group_id => group.id, :source => vote)
        end

        if vote_value >= 300
          vuser.find_badge_on(group,"service_medal") || user_badges.create!(:token => "service_medal", :type => "silver", :group_id => group.id, :source => vote)
        end

        if vote_value >= 500 && vuser.votes_down <= 10
          vuser.find_badge_on(group,"popstar") || user_badges.create!(:token => "popstar", :group_id => group.id, :source => vote)
        end

        if vote_value >= 1000 && vuser.votes_down <= 10
          vuser.find_badge_on(group,"rockstar") || user_badges.create!(:token => "rockstar", :group_id => group.id, :source => vote)
        end
      end

      # questions
      if voteable.kind_of?(Question) && vuser = voteable.user
        user_badges = vuser.badges

        if vote.value == 1
          vuser.find_badge_on(group, "student") || user_badges.create!(:token => "student", :group_id => group.id, :source => voteable)
        end

        if voteable.votes_average >= 10
          user_badges.find(:first, :token => "good_question", :source_id => voteable.id, :group_id => group.id) || user_badges.create!(:token => "good_question", :type => "silver", :group_id => group.id, :source => voteable)
        end
      end

      # answers
      if voteable.kind_of?(Answer) && voteable.parent_id.nil? && (vuser = voteable.user)
        user_badges = vuser.badges

        if voteable.votes_average >= 10
          user_badges.find(:first, :token => "good_answer", :group_id => group.id, :source_id => voteable.id) || user_badges.create!(:token => "good_answer", :type => "silver", :group_id => group.id, :source => voteable)
        end

        if vote.value == 1
          stats = vuser.stats(:tag_votes)
          tags = voteable.question.tags
          tokens = Set.new(Badge.TOKENS)
          tags.delete_if { |t| tokens.include?(t) }

          stats.vote_on_tags(tags)

          tags.each do |tag|
            next if stats.tag_votes[tag].blank?

            badge_type = nil
            votes = stats.tag_votes[tag]+1
            if votes >= 200 && votes < 400
              badge_type = "bronze"
            elsif votes >= 400 && votes < 1000
              badge_type = "silver"
            elsif votes >= 1000
              badge_type = "gold"
            end

            if badge_type && vuser.find_badge_on(group, tag, :type => badge_type).nil?
              vuser.badges.create!(:token => tag, :type => badge_type, :group_id => group.id, :source => voteable, :for_tag => true)
            end
          end
        end
      end
    end

    expose :on_activity
    def on_activity(payload)
      group_id, user_id = payload
      user = User.find(user_id, :select => [:_id])
      group = Group.find(group_id, :select => [:_id])

      days = user.stats(:activity_days).activity_days[group_id]
      if days > 8 && user.find_badge_on(group, "shapado").nil?
        user.badges.create!(:token => "shapado", :group_id => group_id)
      elsif days > 20 && user.find_badge_on(group, "addict").nil?
        user.badges.create!(:token => "addict", :group_id => group_id)
      elsif days > 100 && user.find_badge_on(group, "fanatic").nil?
        user.badges.create!(:token => "fanatic", :group_id => group_id)
      end
    end

    expose :on_update_answer
    def on_update_answer(payload)
      answer = Answer.find(payload.first)
      user = answer.updated_by

      user.find_badge_on(answer.group, "editor") || user.badges.create!(:token => "editor", :group_id => answer.group_id)
    end

    expose :on_comment
    def on_comment(payload)
      question_id, comment_id = payload
      comment = Answer.find(comment_id)
      group = comment.group
      user = comment.user

      if user.answers.count(:group_id => comment.group_id, :parent_id => {:$ne => nil}) >= 10
        user.find_badge_on(group, "commentator") || user.badges.create!(:token => "commentator", :group_id => group.id, :source => comment)
      end
    end

    expose :on_question_favorite
    def on_question_favorite(payload)
      question = Question.find(payload.first)
      user = question.user
      group = question.group
      if question.favorites_count >= 25
        user_badges = user.badges
        user_badges.find(:first, :token => "famous_question", :group_id => group.id, :source_id => question.id) ||
        user_badges.create!(:token => "famous_question", :type => "gold", :group_id => group.id, :source => question)
      end
    end
  end
  Magent.register(Judge.new)
end

if $0 == __FILE__
  Magent::Processor.new(Magent.current_actor).run!
end
