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
        answer.user.find_badge_on(group,"troubleshooter") || create_badge(answer.user, group, :token => "troubleshooter", :type => "bronze", :group => group, :source => answer)
      end

      if question.answer == answer && answer.votes_average >= 40
        answer.user.find_badge_on(group,"guru") || create_badge(answer.user, group, :token => "guru", :type => "silver", :group => group, :source => answer)
      end

      if question.answer == answer && answer.votes_average > 2
        user_badges = answer.user.badges
        answer.user.find_badge_on(group,"tutor") || create_badge(answer.user, group, :token => "tutor", :type => "bronze", :group => group, :source => answer)
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

    expose :on_view_question
    def on_view_question(payload)
      question = Question.find(payload.first)
      user = question.user
      group = question.group

      views = question.views_count
      opts = {:source_id => question.id, :source_type => "Question"}
      if views > 1000 && user.find_badge_on(group, "popular_question", opts).nil?
        create_badge(user, group, :token => "popular_question", :group_id => group.id, :source => question)
      elsif views > 2500 && user.find_badge_on(group, "notable_question", opts).nil?
        create_badge(user, group, :token => "notable_question", :group_id => group.id, :source => question)
      elsif views > 10000 && user.find_badge_on(group, "famous_question", opts).nil?
        create_badge(user, group, :token => "famous_question", :group_id => group.id, :source => question)
      end
    end

    expose :on_ask_question
    def on_ask_question(payload)
      question = Question.find(payload.first)
      user = question.user
      group = question.group

      if group.questions.count(:user_id => user.id) == 1
        user_badges = user.badges
        user.find_badge_on(group, "inquirer") || create_badge(user, group, :token => "inquirer", :type => "bronze", :group_id => group.id, :source => question)
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

    # TODO: awful, refactor!
    expose :on_vote
    def on_vote(payload)
      vote = Vote.find(payload.first)
      user = vote.user
      voteable = vote.voteable
      group = vote.group

      if vote.value == -1
        user_badges = user.badges
        user.find_badge_on(group,"critic") || create_badge(user, group, :token => "critic", :type => "bronze", :group_id => group.id, :source => vote)
      else
        user_badges = user.badges
        user.find_badge_on(group,"supporter") || create_badge(user, group, :token => "supporter", :type => "bronze", :group_id => group.id, :source => vote)
      end

      if user.stats(:views_count).views_count >= 10000
        user.find_badge_on(group,"popular_person") || create_badge(user, group, :token => "popular_person", :type => "silver", :group_id => group.id)
      end

      # users
      if vuser = voteable.user
        user_badges = vuser.badges
        vote_value = vuser.votes_up[group.id] ? vuser.votes_up[group.id] : 0

        if vote_value >= 100
          vuser.find_badge_on(group,"effort_medal") || create_badge(vuser, group, :token => "effort_medal", :type => "silver", :group_id => group.id, :source => vote)
        end

        if vote_value >= 200
          vuser.find_badge_on(group,"merit_medal") || create_badge(vuser, group, :token => "merit_medal", :type => "silver", :group_id => group.id, :source => vote)
        end

        if vote_value >= 300
          vuser.find_badge_on(group,"service_medal") || create_badge(vuser, group, :token => "service_medal", :type => "silver", :group_id => group.id, :source => vote)
        end

        if vote_value >= 500 && vuser.votes_down <= 10
          vuser.find_badge_on(group,"popstar") || create_badge(vuser, group, :token => "popstar", :group_id => group.id, :source => vote)
        end

        if vote_value >= 1000 && vuser.votes_down <= 10
          vuser.find_badge_on(group,"rockstar") || create_badge(vuser, group, :token => "rockstar", :group_id => group.id, :source => vote)
        end
      end

      # questions
      if voteable.kind_of?(Question) && vuser = voteable.user
        user_badges = vuser.badges

        if vote.value == 1
          vuser.find_badge_on(group, "student") || create_badge(vuser, group, :token => "student", :group_id => group.id, :source => voteable)
        end

        if voteable.votes_average >= 10
          user_badges.first( :token => "good_question", :source_id => voteable.id, :group_id => group.id) || create_badge(vuser, group, :token => "good_question", :group_id => group.id, :source => voteable)
        end
      end

      # answers
      if voteable.kind_of?(Answer) && (vuser = voteable.user)
        user_badges = vuser.badges

        if voteable.votes_average >= 10
          user_badges.first(:token => "good_answer", :group_id => group.id, :source_id => voteable.id) || create_badge(vuser, group, :token => "good_answer", :type => "silver", :group_id => group.id, :source => voteable)
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
              create_badge(vuser, group, :token => tag, :type => badge_type, :group_id => group.id, :source => voteable, :for_tag => true)
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
        create_badge(user, group, :token => "shapado", :group_id => group_id)
      elsif days > 20 && user.find_badge_on(group, "addict").nil?
        create_badge(user, group, :token => "addict", :group_id => group_id)
      elsif days > 100 && user.find_badge_on(group, "fanatic").nil?
        create_badge(user, group, :token => "fanatic", :group_id => group_id)
      end
    end

    expose :on_update_answer
    def on_update_answer(payload)
      answer = Answer.find(payload.first)
      user = answer.updated_by

      user.find_badge_on(answer.group, "editor") || create_badge(user, answer.group, :token => "editor", :group_id => answer.group_id)
    end

    expose :on_comment
    def on_comment(payload)
      comment_id = payload.first
      comment = Comment.find(comment_id)
      commentable = comment.commentable
      group = comment.group
      user = comment.user

      if user.comments.count(:group_id => comment.group_id, :_type => {:$ne => "Answer"}) >= 10
        user.find_badge_on(group, "commentator") || create_badge(user, group, :token => "commentator", :group_id => group.id, :source => comment)
      end
    end

    expose :on_question_favorite
    def on_question_favorite(payload)
      question = Question.find(payload.first)
      user = question.user
      group = question.group
      if question.favorites_count >= 25 &&
          user.badges.find_badge_on(group, "favorite_question", :source_id => question.id).nil?
        create_badge(user, group, :token => "favorite_question",
                                  :group_id => group.id,
                                  :source => question)
      end
    end

    private
    def create_badge(user, group, opts)
      badge = user.badges.create!(opts)
      if !badge.new? && !user.email.blank? && user.notification_opts["activities"] == "1"
        Notifier.deliver_earned_badge(user, group, badge)
      end
    end
  end
  Magent.register(Judge.new)
end

if $0 == __FILE__
  Magent::Processor.new(Magent.current_actor).run!
end
