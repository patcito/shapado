desc "Fix all"
task :fixall => [:environment, "fixdb:wiki", "fixdb:notif_rules", "fixdb:group_config"] do
end

namespace :fixdb do
  desc "Fix wiki"
  task :wiki => :environment do
    puts "Updating #{Question.count(:versions => {:$exists => true})} questions"
    Question.find_each(:versions => {:$exists => true}) do |question|
      question.versions.each do |version|
        new_data = {}
        version.data.each do |k, v|
          next unless v.kind_of?(Array)
          new_data[k] = v.first
        end

        %w[title body tags].each do |k|
          if !version.data[k]
            new_data[k] = question[k]
          end
        end
        version.data = new_data
      end
      question.save(:validate => false)
    end

    puts "Updating #{Answer.count(:versions => {:$exists => true})} answers"
    Answer.find_each(:versions => {:$exists => true}) do |answer|
      answer.versions.each do |version|
        new_data = {}
        version.data.each do |k, v|
          next unless v.kind_of?(Array)
          new_data[k] = v.first
        end

        %w[body].each do |k|
          if !version.data[k]
            new_data[k] = answer[k]
          end
        end

        version.data = new_data
      end
      answer.save(:validate => false)
    end
  end

  desc "Fix notification rules"
  task :notif_rules => :environment do
    User.find_each do |user|
      user.save(:validate => false)
    end
  end

  desc "Fix group configuration"
  task :group_config => :environment do
    $stderr.puts "Updating #{User.count} users..."
    destroy = !!ENV['destroy']

    User.find_each do |user|
      (user[:reputation]||{}).each do |group_id, v|
        next if Group.find(group_id, :select => [:_id]).nil?

        user.config_for(group_id).reputation = v
      end
      user[:reputation] = nil if destroy

      (user[:votes_up]||{}).each do |group_id, v|
        next if Group.find(group_id, :select => [:_id]).nil?
        user.config_for(group_id).votes_up = v
      end
      user[:votes_up] = nil if destroy

      (user[:votes_down]||{}).each do |group_id, v|
        next if Group.find(group_id, :select => [:_id]).nil?
        user.config_for(group_id).votes_down = v
      end
      user[:votes_down] = nil if destroy

      (user[:preferred_tags]||{}).each do |group_id, v|
        next if Group.find(group_id, :select => [:_id]).nil?
        user.config_for(group_id).preferred_tags = v
      end
      user[:preferred_tags] = nil if destroy

      cursor = MongoMapper.database.collection("members").find({:user_id => user.id})

      while member = cursor.next_document
        next if Group.find(member["group_id"], :select => [:_id]).nil?

        user.config_for(member["group_id"]).role = member["role"]
      end

      stats = user.stats.reload
      (stats[:activity_days]||{}).each do |group_id, v|
        next if Group.find(group_id, :select => [:_id]).nil?
        user.config_for(group_id).activity_days = v
      end

      (stats[:last_activity_at]||{}).each do |group_id, v|
        next if Group.find(group_id, :select => [:_id]).nil?
        user.config_for(group_id).last_activity_at = v
      end

      stats_atts = stats.attributes
      user_atts = user.attributes

      if destroy
        MongoMapper.database.drop_collection("members")

        %w[activity_days last_activity_at].each do |key|
          stats_atts.delete(key)
        end

        %w[reputation votes_up votes_down preferred_tags].each do |key|
          user_atts.delete(key)
        end
      end

      user.collection.save(user_atts)
      UserStat.collection.save(stats_atts)
    end
  end
end

