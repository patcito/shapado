require 'faker'

namespace :populator do
  desc "Creates 10 random questions"
  task :questions => :environment do
    users = User.find(:all, :limit => 20)
    raise "There are no users!" if users.empty?

    10.times do
      q = Question.new(:title =>  Faker::Lorem.words(rand(6)+6).join(" "),
                       :body => Faker::Lorem.paragraphs(rand(10)+1),
                       :answered => (rand(100) % 2 == 0))
      q.user = users.rand

      rand(20).times do |i|
        q.answers << Answer.new(:user => users.rand,
                                :body => Faker::Lorem.paragraphs(rand(10)+1))
      end

      q.save!
    end
  end

  desc "Creates 10 random users"
  task :users => :environment do
    10.times do
      user = User.create(:login => Faker::Internet.user_name,
                         :email => Faker::Internet.email,
                         :name => Faker::Name.name,
                         :password => "test123", :password_confirmation => "test123")
    end
  end
end

