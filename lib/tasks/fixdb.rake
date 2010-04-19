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
end

