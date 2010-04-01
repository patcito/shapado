module JudgeActions
  module Votes
    def on_vote_question(payload)
      vote = Vote.find(payload.first)

      user = vote.user
      question = vote.voteable
      group = vote.group

      if vuser = question.user
        if vote.value == 1
          create_badge(vuser, group, :token => "student", :source => question, :unique => true)
        end

        if question.votes_average >= 10
          create_badge(vuser, group, {:token => "nice_question", :source => question}, {:unique => true, :source_id => question.id})
        end

        if question.votes_average >= 25
          create_badge(vuser, group, {:token => "good_question", :source => question}, {:unique => true, :source_id => question.id})
        end

        if question.votes_average >= 100
          create_badge(vuser, group, {:token => "great_question", :source => question}, {:unique => true, :source_id => question.id})
        end
      end

      on_vote(vote)
      on_vote_user(vote)
    end

    def on_vote_answer(payload)
      vote = Vote.find(payload.first)
      user = vote.user
      answer = vote.voteable
      group = vote.group

      if vuser = answer.user
        if answer.votes_average >= 10
          create_badge(vuser, group, {:token => "nice_answer", :source => answer}, {:unique => true, :source_id => answer.id})
        end

        if answer.votes_average >= 25
          create_badge(vuser, group, {:token => "good_answer", :source => answer}, {:unique => true, :source_id => answer.id})
        end

        if answer.votes_average >= 100
          create_badge(vuser, group, {:token => "great_answer", :source => answer}, {:unique => true, :source_id => answer.id})
        end

        if (answer.created_at - answer.question.created_at) >= 60.days && answer.votes_average >= 5
          create_badge(vuser, group, {:token => "necromancer", :source => answer}, {:unique => true, :source_id => answer.id})
        end

        if vuser.id == answer.question.user_id && answer.votes_average >= 3
          create_badge(vuser, group, {:token => "self-learner", :source => answer, :unique => true})
        end

        if vote.value == 1
          stats = vuser.stats(:tag_votes)
          tags = answer.question.tags
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
              create_badge(vuser, group, :token => tag, :type => badge_type, :source => answer, :for_tag => true)
            end
          end
        end
      end

      on_vote(vote)
      on_vote_user(vote)
    end

    private
    def on_vote(vote)
      group = vote.group
      user = vote.user

      if vote.value == -1
        create_badge(user,  group,  :token => "critic", :source => vote, :unique => true)
      else
        create_badge(user, group, :token => "supporter", :source => vote, :unique => true)
      end

      if user.config_for(group).views_count >= 10000
        create_badge(user, group, :token => "popular_person", :unique => true)
      end

      if user.votes.count(:group_id => group.id) >= 300
        create_badge(user, group, :token => "civic_duty", :unique => true)
      end
    end

    def on_vote_user(vote)
      group = vote.group
      user = vote.user

      vuser = vote.voteable.user
      return if vuser.nil?

      vote_value = vuser.config_for(group).votes_up

      if vote_value >= 100
        create_badge(vuser, group, :token => "effort_medal",  :source => vote, :unique => true)
      end

      if vote_value >= 200
        create_badge(vuser, group, :token => "merit_medal", :source => vote, :unique => true)
      end

      if vote_value >= 300
        create_badge(vuser,  group, :token => "service_medal", :source => vote, :unique => true)
      end

      if vote_value >= 500 && vuser.config_for(group).votes_down <= 10
        create_badge(vuser, group, :token => "popstar", :source => vote, :unique => true)
      end

      if vote_value >= 1000 && vuser.config_for(group).votes_down <= 10
        create_badge(vuser, group, :token => "rockstar",  :source => vote, :unique => true)
      end
    end
  end
end
