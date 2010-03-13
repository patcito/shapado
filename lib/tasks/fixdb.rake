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

    User.find_each do |user|
      (user[:reputation]||{}).each do |group_id, v|
        next if Group.find(group_id, :select => [:_id]).nil?

        user.config_for(group_id).reputation = v
      end

      (user[:votes_up]||{}).each do |group_id, v|
        next if Group.find(group_id, :select => [:_id]).nil?
        user.config_for(group_id).votes_up = v
      end

      (user[:votes_down]||{}).each do |group_id, v|
        next if Group.find(group_id, :select => [:_id]).nil?
        user.config_for(group_id).votes_down = v
      end

      (user[:preferred_tags]||{}).each do |group_id, v|
        next if Group.find(group_id, :select => [:_id]).nil?
        user.config_for(group_id).preferred_tags = v
      end

      user.memberships.each do |member|
        next if Group.find(member.group_id, :select => [:_id]).nil?

        user.config_for(member.group_id).role = member.role
      end

      stats = user.stats.reload
      (stats.activity_days||{}).each do |group_id, v|
        next if Group.find(group_id, :select => [:_id]).nil?
        user.config_for(group_id).activity_days = v
      end

      (stats.last_activity_at||{}).each do |group_id, v|
        next if Group.find(group_id, :select => [:_id]).nil?
        user.config_for(group_id).last_activity_at = v
      end


      user.save(:validate => false)
    end
  end
end

