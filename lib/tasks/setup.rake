desc "Setup application"
task :bootstrap => [:environment, "setup:reset",
                    "setup:create_admin",
                    "setup:default_group",
                    "setup:create_widgets"] do
end

desc "Upgrade"
task :upgrade => [:environment,
                  "setup:create_widgets",
                  "setup:pioneer"] do
end

namespace :setup do
  desc "Reset databases"
  task :reset => [:environment] do
    MongoMapper.connection.drop_database(MongoMapper.database.name)
  end

  desc "Reset admin password"
  task :reset_password => :environment do
    admin = User.find_by_login("admin")
    admin.crypted_password = nil
    admin.password = "admins"
    admin.password_confirmation = "admins"
    admin.save
  end

  desc "Create the default group"
  task :default_group => [:environment] do
    categories = %w[technology business science politics religion
                               sports entertainment gaming lifestyle offbeat]

    subdomain = AppConfig.application_name.gsub(/[^A-Za-z0-9\s\-]/, "")[0,20].strip.gsub(/\s+/, "-").downcase
    default_group = Group.new(:name => AppConfig.application_name,
                              :domain => AppConfig.domain,
                              :subdomain => subdomain,
                              :domain => AppConfig.domain,
                              :description => "question-and-answer website",
                              :legend => "question and answer website",
                              :default_tags => categories,
                              :state => "active")

    default_group.save!
    if admin = User.find_by_login("admin")
      default_group.owner = admin
      default_group.add_member(admin, "owner")
    end
    default_group.logo_data = RAILS_ROOT+"/public/images/logo.png"
    default_group.save
  end

  desc "Create default widgets"
  task :create_widgets => :environment do
    default_group = Group.find_by_domain(AppConfig.domain)

    default_group.widgets << GroupsWidget.create(:position => 0)
    default_group.widgets << BadgesWidget.create(:position => 1)
    default_group.save!
  end

  desc "Create admin user"
  task :create_admin => [:environment] do
    admin = User.new(:login => "admin", :password => "admins",
                                        :password_confirmation => "admins",
                                        :email => "shapado@shapado.com",
                                        :role => "admin")
    admin.save!
  end

  desc "Pioneer"
  task :pioneer => :environment do
    puts "Processing #{User.count} users"
    User.all.each do |user|
      group_ids = user.reputation.map {|group_id,_| group_id }
      group_ids.each do |group_id|
        votes_up = 0
        votes_down = 0
        user.votes_up[group_id] = votes_up
        user.votes_down[group_id] = votes_down

        Badge.create(:token => "pioneer", :type => "bronze", :user => user, :group_id => group_id, :created_at => user.created_at)

        questions = user.questions.all(:group_id => group_id)
        if questions.count > 0
          Badge.create(:token => "inquirer", :type => "bronze", :user => user,
                       :group_id => group_id, :created_at => questions.first.created_at)

          questions.each do |question|
            if answer = question.answer
              Badge.create(:token => "troubleshooter", :type => "bronze",
                           :user => answer.user, :group_id => group_id, :created_at => answer.created_at)
            end

            votes_up = question.votes.group_by { |vote| vote.value }[1].try(:count).to_i
            votes_down = question.votes.group_by { |vote| vote.value }[-1].try(:count).to_i

            user.votes_up[group_id] += votes_up
            user.votes_down[group_id] += votes_down
            user.stats.add_question_tags(*question.tags)
          end
        end

        answers = user.answers.all(:group_id => group_id)
        if answers.count > 0
          answers.each do |answer|
            user.stats.add_answer_tags(*answer.question.tags)

            votes_up = answer.votes.group_by { |vote| vote.value }[1].try(:count).to_i
            votes_down = answer.votes.group_by { |vote| vote.value }[-1].try(:count).to_i

            user.votes_up[group_id] += votes_up
            user.votes_down[group_id] += votes_down
          end
        end

        $stdout.print "."
        $stdout.flush if rand(10) == 5
      end

      user.save(false)
    end
  end
end

