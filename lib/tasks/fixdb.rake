desc "Fix all"
task :fixall => [:environment, "fixdb:badges", "fixdb:questions"] do
end

namespace :fixdb do
  task :badges => :environment do
    puts "Updating #{User.count} users..."

    User.find_each do |user|
      user.membership_list.each do |group_id, membership|
        if membership["last_activity_at"].nil?
          user.unset(:"membership_list.#{group_id}")
        else
          gold_count = user.badges.count(:group_id => group_id, :type => "gold")
          bronze_count = user.badges.count(:group_id => group_id, :type => "bronze")
          silver_count = user.badges.count(:group_id => group_id, :type => "silver")
          editor = user.badges.first(:group_id => group_id, :token => "editor")

          if editor.present?
            user.set({"membership_list.#{group_id}.is_editor" => true})
          end

          user.set({"membership_list.#{group_id}.bronze_badges_count" => bronze_count})
          user.set({"membership_list.#{group_id}.silver_badges_count" => silver_count})
          user.set({"membership_list.#{group_id}.gold_badges_count" => gold_count})
        end
      end
    end
  end

  task :questions => :environment do
    Group.find_each do |group|
      tag_list = group.tag_list

      Question.find_each(:group_id => group.id) do |question|
        if question.last_target.present?
          target = question.last_target
          question.set({:last_target_date => (target.updated_at||target.created_at).utc})
        elsif question.title.present?
          question.set({:last_target_date => (question.activity_at || question.updated_at).utc})
        end

        tag_list.add_tags(*question.tags)
      end
    end
  end
end

