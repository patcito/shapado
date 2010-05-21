desc "Fix all"
task :fixall => [:environment, "fixdb:badges", "fixdb:questions", "fixdb:update_widgets", "fixdb:tokens"] do
end

namespace :fixdb do
  task :badges => :environment do
    puts "Updating #{User.count} users..."

    Badge.set({:token => "tutor"}, {:type => "bronze"})

    User.find_each(:select => ["membership_list"]) do |user|
      user.membership_list.each do |group_id, membership|
        if membership["last_activity_at"].nil? && membership["reputation"] == 0
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

  task :update_widgets => :environment do
    Group.find_each do |group|
      puts "Updating #{group["name"]} widgets"

      MongoMapper.database.collection("widgets").find({:group_id => group["_id"]},
                                                      {:sort => ["position", :asc]}).each do |w|
        w.delete("position"); w.delete("group_id")
        MongoMapper.database.collection("groups").update({:_id => group["_id"]},
                                                         {:$addToSet => {:widgets => w}},
                                                         {:upsert => true, :safe => true})
      end
    end
    MongoMapper.database.collection("widgets").drop
  end

  task :tokens => :environment do
    User.find_each do |user|
      user.set({"feed_token" => UUIDTools::UUID.random_create.hexdigest,
                "authentication_token" => UUIDTools::UUID.random_create.hexdigest})
    end
  end
end

