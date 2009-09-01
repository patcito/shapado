namespace :fixdb do
  task :hotness => :environment do
    Question.all.each do |q|
      q.hotness = q.votes_count + q.answers_count
      q.save
    end
  end
end

