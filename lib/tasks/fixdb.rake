desc "Fix all"
task :fixall => [:environment, "fixdb:wiki", "fixdb:notif_rules"] do
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
end
