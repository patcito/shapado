desc "Fix all"
task :fixall => [:environment, "fixdb:pages", "fixdb:comment_voteable", "fixdb:comments", "fixdb:badges"] do
end

namespace :fixdb do
  task :pages => :environment do
    Group.all(:language.nin => [nil, ""]).each do |g|
      g.pages.destroy_all(:language.ne => g.language)
    end
  end

  desc "initialize values to become comments as voteable"
  task :comment_voteable => :environment do
    Comment.collection.update({:_type => "Comment"}, {:$set => {:votes_count => 0,
                                                                :votes_average => 0}},
                               :upsert => true,
                               :safe => true,
                               :multi => true)
  end

  task :comments => :environment do
    Comment.find_each(:group_id => nil) do |comment|
      group_id = comment.commentable.group_id
      comment.set({:group_id => group_id})
    end
  end

  task :badges => :environment do
    User.find_each do |user|
      user.membership_list.each do |group_id, membership|
        if membership["last_activity_at"].nil?
          user.unset(:"membership_list.#{group_id}")
        else
          gold_count = user.badges.count(:group_id => group_id, :type => "gold")
          bronze_count = user.badges.count(:group_id => group_id, :type => "bronze")
          silver_count = user.badges.count(:group_id => group_id, :type => "silver")

          user.set({"membership_list.#{group_id}.bronze_badges_count" => bronze_count})
          user.set({"membership_list.#{group_id}.silver_badges_count" => silver_count})
          user.set({"membership_list.#{group_id}.gold_badges_count" => gold_count})
        end
      end
    end
  end

  task :dates => :environment do
    Question.find_each do |question|
      if question.last_target.present?
        target = question.last_target
        question.set({:last_target_date => (target.updated_at||target.created_at).utc})
      elsif question.title.present?
        question.set({:last_target_date => (question.activity_at || question.updated_at).utc})
      end
    end
  end
end

