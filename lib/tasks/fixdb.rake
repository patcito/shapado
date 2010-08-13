desc "Fix all"
task :fixall => [:environment, "fixdb:badges", "fixdb:questions", "fixdb:update_widgets", "fixdb:tokens", "fixdb:es419"] do
end

namespace :fixdb do
  task :es419 => :environment do
    puts "Updating Group language from es-AR to es-419"
    User.set({:language => 'es-AR'},{:language => 'es-419'})

    puts "Updating User language from es-AR to es-419"
    User.set({:language => 'es-AR'},{:language => 'es-419'})

    puts "Updating Questions language from es-AR to es-419"
    User.set({:language => 'es-AR'},{:language => 'es-419'})

    puts "Updating Comments language from es-AR to es-419"
    User.set({:language => 'es-AR'},{:language => 'es-419'})

    puts "Updating Pages language from es-AR to es-419"
    User.set({:language => 'es-AR'},{:language => 'es-419'})

    puts "Updating Answer language from es-AR to es-419"
    User.set({:language => 'es-AR'},{:language => 'es-419'})
  end
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

  task :reputation_rewards => :environment do
    Group.find_each do |g|
      [["vote_up_question", "undo_vote_up_question"],
       ["vote_down_question", "undo_vote_down_question"],
       ["question_receives_up_vote", "question_undo_up_vote"],
       ["question_receives_down_vote", "question_undo_down_vote"],
       ["vote_up_answer", "undo_vote_up_answer"],
       ["vote_down_answer", "undo_vote_down_answer"],
       ["answer_receives_up_vote", "answer_undo_up_vote"],
       ["answer_receives_down_vote", "answer_undo_down_vote"],
       ["answer_picked_as_solution", "answer_unpicked_as_solution"]].each do |action, undo|
         if g.reputation_rewards[action] > (g.reputation_rewards[undo]*-1)
           print "fixing #{g.name} #{undo} reputation rewards\n"
           g.set("reputation_rewards.#{undo}" => g.reputation_rewards[action]*-1)
         end
       end
    end
  end

  task :unsolve_questions => :environment do
    Question.find_each(:accepted => true) do |q|
      if q.answer.nil?
        print "."
        q.set({:answer_id => nil, :accepted => false})
      end
    end
  end
end

