desc "Fix all"
task :fixall => [:environment, "fixdb:add_accepted"] do
end

namespace :fixdb do
  desc "orphan answers"
  task :add_accepted => [:environment] do
    Question.set({:answered => true}, {:accepted => true})
  end
end

