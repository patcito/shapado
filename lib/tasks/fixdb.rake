desc "Fix all"
task :fixall => [:environment, "fixdb:groups", "fixdb:notifs", "fixdb:votes", "fixdb:answers"] do
end

namespace :fixdb do
  desc "Fix votes"
  task :votes => :environment do
    $stderr.puts "Updating #{Vote.count} votes..."
    Vote.all.each do |vote|
      vote.group = vote.voteable.group
      if vote.save(false)
        $stdout.print "."
      else
        $stdout.print "F"
      end

      $stdout.flush if rand(10) == 5
    end
  end

  desc "Fix groups"
  task :groups => :environment do
    $stderr.puts "Updating #{Group.count} groups..."
    Group.all.each do |group|
      GroupsWidget.create(:position => 0, :group_id => group.id) unless group.isolate || group.private
      UsersWidget.create(:position => 1, :group_id => group.id)
      BadgesWidget.create(:position => 2, :group_id => group.id)
    end
  end

  desc "Fix Notifications"
  task :notifs => :environment do
    $stderr.puts "Updating #{User.count} users..."
    User.all.each do |user|
      user.notification_opts["give_advice"] ||= "1"
      user.save(false)
    end
  end

  desc "Fix questions"
  task :questions => :environment do
    $stderr.puts "Updating #{Question.count} questions..."
    Question.all.each do |question|
      if question.views_count > 500
        if question.views_count > 1000
          question.views_count = rand(200)+300
        else
          question.views_count = question.views_count-500
        end
      end
      question.save(false)
      $stdout.print "."
      $stdout.flush if rand(10) == 5
    end
  end

  desc "Check Answers"
  task :answers => :environment do
    $stderr.puts "Checking #{Answer.count} answers..."
    Answer.all.each do |answer|
      if answer.group_id.blank?
        if answer.question.present? && q = answer.question
          answer.group = q.group
        end
        answer.save(false)
      end

      $stdout.print "."
      $stdout.flush if rand(10) == 5
    end
  end

  desc "Answers to Comments"
  task :answers_to_comments => :environment do
    db = MongoMapper.database
    comments = db.collection("comments")

    comments.find.each do |c|
      c["_type"] ||= "Comment"
      if c["_id"].kind_of?(Mongo::ObjectID)
        comments.remove(:_id => c["_id"])
        c["_id"] = c["_id"].to_s
      end
      comments.save(c)
    end

    db.collection("answers").find.each do |a|
      if a["parent_id"]
        a["commentable_id"] = a["parent_id"]
        a["commentable_type"] = "Answer"
        a["_type"] = "Comment"

        a.delete("parent_id")
      else
        a["_type"] = "Answer"
      end
      comments.insert(a, :safe => true)
    end
    db.drop_collection("answers")
  end
end
