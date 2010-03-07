module JudgeActions
  module Votes
    def on_vote_question(payload)
      vote = Vote.find(payload.first)
      user = vote.user
      question = vote.voteable
      group = vote.group
      
      if voteable.kind_of?(Question) && vuser = voteable.user
        user_badges = vuser.badges

        if vote.value == 1
          vuser.find_badge_on(group, "student") || create_badge(vuser, group, :token => "student", :group_id => group.id, :source => voteable)
        end

        if voteable.votes_average >= 10
          user_badges.first( :token => "good_question", :source_id => voteable.id, :group_id => group.id) || create_badge(vuser, group, :token => "good_question", :group_id => group.id, :source => voteable)
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

      if vuser = voteable.user
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
              create_badge(vuser, 
                           group, 
                           :token => tag, 
                           :type => badge_type, 
                           :group_id => group.id, 
                           :source => voteable, 
                           :for_tag => true)
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
        user_badges = user.badges
        user.find_badge_on(group,"critic") || create_badge(user, 
                                                           group, 
                                                           :token =>
"critic", 
                                                           :type => "bronze",

                                                           :group_id =>
group.id, 
                                                           :source => vote)
      else
        user_badges = user.badges
        user.find_badge_on(group,"supporter") || create_badge(user, 
                                                              group, 
                                                              :token =>
"supporter", 
                                                              :type => "bronze",

                                                              :group_id =>
group.id, 
                                                              :source => vote)
      end

      if user.stats(:views_count).views_count >= 10000
        user.find_badge_on(group,"popular_person") || create_badge(user, 
                                                                   group, 
                                                                   :token
=> "popular_person", 
                                                                   :type =>
"silver", 
                                                                   :group_id =>
group.id)
      end
    end
    
    def on_vote_user(vote)
      group = vote.group
      user = vote.user

      vuser = voteable.user
      return if vuser.nil?

      user_badges = vuser.badges
      vote_value = vuser.votes_up[group.id] ? vuser.votes_up[group.id] : 0

      if vote_value >= 100
        vuser.find_badge_on(group,"effort_medal") || create_badge(vuser, 
                                                                  group,

                                                                  :token =>
"effort_medal", 
                                                                  :type =>
"silver", 
                                                                  :group_id =>
group.id, 
                                                                  :source =>
vote)
      end

      if vote_value >= 200
        vuser.find_badge_on(group,"merit_medal") || create_badge(vuser, 
                                                                 group,

                                                                 :token =>
"merit_medal", 
                                                                 :type =>
"silver", 
                                                                 :group_id =>
group.id, 
                                                                 :source =>
vote)
      end

      if vote_value >= 300
        vuser.find_badge_on(group,"service_medal") || create_badge(vuser, 
                                                                   group,

                                                                   :token =>
"service_medal", 
                                                                   :type =>
"silver", 
                                                                   :group_id =>
group.id, 
                                                                   :source =>
vote)
      end

      if vote_value >= 500 && vuser.votes_down <= 10
        vuser.find_badge_on(group,"popstar") || create_badge(vuser, 
                                                             group,
                                                             :token =>
"popstar", 
                                                             :group_id =>
group.id, 
                                                             :source => vote)
      end

      if vote_value >= 1000 && vuser.votes_down <= 10
        vuser.find_badge_on(group,"rockstar") || create_badge(vuser, 
                                                              group,
                                                              :token =>
"rockstar", 
                                                              :group_id =>
group.id, 
                                                              :source => vote)
      end
    end
  end
end
