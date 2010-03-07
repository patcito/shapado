module JudgeActions
  module Activities
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
    
    def on_update_answer(payload)
      answer = Answer.find(payload.first)
      user = answer.updated_by

      user.find_badge_on(answer.group, "editor") || create_badge(user, answer.group, :token => "editor", :group_id => answer.group_id)
    end
    
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
    
    def on_follow(payload)
      follower = User.find(payload.shift)
      followed = User.find(payload.shift)
      group = Group.find(payload.shift)

      if follower.following_count < 5 && follower.find_badge_on(group, "friendly").nil?
        create_badge(follower, group, :token => "friendly",:group_id => group.id, :source => followed)
      end

      if followed.followers_count >= 10 && followed.find_badge_on(group, "interesting_person").nil?
        create_badge(followed, group, :token => "interesting_person",:group_id => group.id)
      elsif followed.followers_count >= 50 && followed.find_badge_on(group, "popular_person").nil?
        create_badge(followed, group, :token => "popular_person",:group_id => group.id)
      elsif followed.followers_count >= 100 && followed.find_badge_on(group, "celebrity").nil?
        create_badge(followed, group, :token => "celebrity",:group_id => group.id)
      end
    end
    
    def on_unfollow(payload)
    end
  end
end