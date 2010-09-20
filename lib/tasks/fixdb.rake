desc "Fix all"
task :fixall => [:environment, "fixdb:reputation_rewards", "fixdb:unsolve_questions", "fixdb:es419", "fixdb:anonymous", "fixdb:flags"] do
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

  task :anonymous => :environment do
    User.set({}, {:anonymous => false})
  end

  task :flags => :environment do
    Group.find_each do |group|
      puts "Updating #{group["name"]} flags"
      count = 0

      MongoMapper.database.collection("flags").find({:group_id => group["_id"]}).each do |flag|
        count += 1
        flag.delete("group_id")
        id = flag.delete("flaggeable_id")
        klass = flag.delete("flaggeable_type")
        flag["reason"] = flag.delete("type")
        if klass == "Answer"
          obj = Answer.find(id)
        elsif klass == "Question"
          obj = Question.find(id)
        end

        obj.add_to_set({:flags => flag})
      end
    end
    MongoMapper.database.collection("falgs").drop
  end
end

