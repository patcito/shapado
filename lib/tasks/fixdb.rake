desc "Fix all"
task :fixall => [:environment, "fixdb:add_accepted"] do
end

namespace :fixdb do
  desc "orphan answers"
  task :add_accepted => [:environment] do
    $stderr.puts "Updating #{Question.count} questions..."

    Question.find_each do |question|
      if question[:answered]
        question[:accepted] = true
      end

      if question.accepted
        question.answered_with = question.answer
      else
        question.answered_with = question.answers.first(:votes_average.gt => 0)
      end

      question.save(:validate => false)

      print "."
      $stdout.flush if rand(10) < 5
    end
  end

  desc "update last activity"
  task :update_dates => [:environment] do
    Question.find_each(:updated_at.gte => 2.hour.ago) do |q|
      if q.last_target.nil? && q.created_at.present?
        if q.answers.count > 0
          answer = q.answers.first(:order => "updated_at desc")
          if answer.comments.count > 0
            Question.update_last_target(q.id, answer.comments.first(:order => "updated_at desc"))
          else
            Question.update_last_target(q.id, answer)
          end
        else
          q.set(:updated_at => q.created_at.utc)
        end
      end
    end
  end
end

