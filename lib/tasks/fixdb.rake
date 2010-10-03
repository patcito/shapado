desc "Fix all"
task :fixall => [:environment, "fixdb:anonymous"] do
end

namespace :fixdb do
  task :anonymous => [:environment] do
    Question.set({:anonymous => nil}, {:anonymous => false})
    Answer.set({:anonymous => nil}, {:anonymous => false})
  end
end

