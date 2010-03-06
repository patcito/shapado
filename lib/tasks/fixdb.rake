desc "Fix all"
task :fixall => [:environment, "fixdb:wiki"] do
end

namespace :fixdb do
  desc "Fix wiki"
  task :wiki => :environment do
    puts "Updating #{Question.count(:versions => {:$exists => true})} questions"
    Question.find_each(:versions => {:$exists => true}) do |question|
      question.versions.each do |version|
        new_data = {}
        version.data.each do |k, v|
          new_data[k] = v.first
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
          new_data[k] = v.first
        end
        version.data = new_data
      end
      answer.save(:validate => false)
    end
  end
end
