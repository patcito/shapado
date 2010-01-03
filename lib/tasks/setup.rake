desc "Setup application"
  task :bootstrap => [:environment, "setup:reset",
                      "setup:create_admin",
                      "setup:default_group",
                      "setup:create_widgets"] do
end

namespace :setup do
  desc "Reset databases"
  task :reset => [:environment] do
    MongoMapper.connection.drop_database(MongoMapper.database.name)
  end

  desc "Create the default group"
  task :default_group => [:environment] do
    categories = %w[technology business science politics religion
                               sports entertainment gaming lifestyle offbeat]

    subdomain = AppConfig.application_name.gsub(/[^A-Za-z0-9\s\-]/, "")[0,20].strip.gsub(/\s+/, "-").downcase
    default_group = Group.new(:name => AppConfig.application_name,
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

  task "Upgrade"
  task :upgrade => [:environment,
                    "setup:create_widgets"] do
  end
end

