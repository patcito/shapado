desc "Setup application"
  task :bootstrap => [:environment, "setup:reset", "setup:create_admin",
                                                   "setup:default_group"] do
end

namespace :setup do
  desc "Reset databases"
  task :reset => [:environment] do
    MongoMapper.connection.drop_database(MongoMapper.database.name)
  end

  desc "Create the default group"
  task :default_group => [:environment] do
    categories = %w[technology programming business science politics religion
                                  sports entertainment gaming lifestyle offbeat]
    default_group = Group.new(:name => AppConfig.application_name,
                           :subdomain => AppConfig.application_name,
                           :description => "question-and-answer website",
                           :legend => "question and answer website",
                           :categories => categories,
                           :state => "active")
    default_group.save!
    default_group.logo_data = RAILS_ROOT+"/public/images/logo.png"
    default_group.save
  end

  desc "Create admin user"
  task :create_admin => [:environment] do
    admin = User.new(:login => "admin", :password => "admins",
                                        :password_confirmation => "admins",
                                        :email => "shapado@shapado.com",
                                        :role => "admin")
    admin.save!
  end

end

