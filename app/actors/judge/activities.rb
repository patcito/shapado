module JudgeActions
  module Activities
    def on_activity(payload)
      group_id, user_id = payload
      user = User.first(:_id => user_id, :select => [:_id])
      group = Group.first(:_id => group_id, :select => [:_id])

      days = user.config_for(group).activity_days
      if days > 100
        create_badge(user, group, :token => "fanatic", :unique => true)
      elsif days > 20
        create_badge(user, group, :token => "addict", :unique => true)
      elsif days > 8
        create_badge(user, group, :token => "shapado", :unique => true)
      end
    end

    def on_update_answer(payload)
      answer = Answer.find(payload.first)
      user = answer.updated_by

      create_badge(user, answer.group, :token => "editor", :unique => true)
    end

    def on_destroy_answer(payload)
      deleter = User.find!(payload.first)
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

    def on_comment(payload)
      comment_id = payload.first
      comment = Comment.find!(comment_id)
      commentable = comment.commentable
      group = comment.group
      user = comment.user

      if user.comments.count(:group_id => comment.group_id, :_type => {:$ne => "Answer"}) >= 10
        create_badge(user, group, :token => "commentator", :source => comment, :unique => true)
      end
    end

    def on_follow(payload)
      follower = User.find(payload.shift)
      followed = User.find(payload.shift)
      group = Group.find(payload.shift)

      if follower.following_count > 1
        create_badge(follower, group, :token => "friendly",:source => followed, :unique => true)
      end

      if followed.followers_count >= 100
        create_badge(followed, group, :token => "celebrity",:unique => true)
      elsif followed.followers_count >= 50
        create_badge(followed, group, :token => "popular_person",:unique => true)
      elsif followed.followers_count >= 10
        create_badge(followed, group, :token => "interesting_person",:unique => true)
      end
    end

    def on_unfollow(payload)
    end

    def on_flag(payload)
      flag = Flag.find(payload.first)
      create_badge(flag.user, flag.group, :token => "citizen_patrol", :source => flag, :unique => true)
    end

    def on_rollback(payload)
      question = Question.find(payload.first)
      create_badge(question.updated_by, question.group, :token => "cleanup", :source => question, :unique => true)
    end
  end
end