
namespace :populator do
  task :populator_env => :environment do
    require 'faker'
  end

  desc "Creates 10 random questions"
  task :questions => :populator_env do
    users = User.find(:all, :limit => 20)
    raise "There are no users!" if users.empty?
    default_group = Group.find_by_name(AppConfig.application_name)

    10.times do
      q = Question.new(:title =>  Faker::Lorem.words(rand(6)+6).join(" "),
                       :body => Faker::Lorem.paragraphs(rand(10)+6),
                       :language => (rand(100) % 2 == 0) ? 'en' : 'es',
                       :tags => Faker::Lorem.words(rand(6)+1),
                       :banned => false)
      q.group = default_group
      q.user = users.rand
      q.save!

      rand(20).times do |i|
        a = Answer.new( :user => users.rand,
                        :body => Faker::Lorem.paragraphs(rand(10)+1),
                        :language => (rand(100) % 2 == 0) ? 'en' : 'es')
        a.group_id = q.group_id
        q.answers << a
        if a.valid?
          q.answer_added!
          rand(10).times do |i|
            f = Flag.new(:user => users.rand,
                         :reason => Flag::TYPES[rand(Flag::TYPES.size)],
                         :banned => false)
          a.flaggs << f
          a.flagged!
          a.save
          end
        end
      end

      rand(10).times do |i|
        f = Flag.new(:user => users.rand,
                     :reason => Flag::REASONS[rand(Flag::REASONS.size)])
        q.flaggs << f
        q.save
        q.flagged!
      end

    end
  end

  desc "Creates 10 random users"
  task :users => :populator_env do
    10.times do
      user = User.create(:login => Faker::Internet.user_name.gsub(/\W/, "-"),
                         :email => Faker::Internet.email,
                         :name => Faker::Name.name,
                         :password => "test123", :password_confirmation => "test123")
    end
  end

  desc "Creates 10 random groups"
  task :groups => :populator_env do
    states = ["active", "pending"]
    users = User.find(:all, :limit => 20)
    raise "There are no users!" if users.empty?
    10.times do
      name = Faker::Name.name
      group = Group.new(:name => Faker::Name.name,
                        :subdomain => name,
                        :description => Faker::Lorem.paragraphs(1),
                        :state => states.rand)
      group.owner = users.rand
      group.save!
    end
  end
end

