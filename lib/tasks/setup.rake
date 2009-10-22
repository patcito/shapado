desc "Setup application"
  task :bootstrap => [:environment, "setup:reset", "setup:default_group"] do
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
                           :categories => categories,
                           :state => "active",
                           :logo => File.read(RAILS_ROOT+"/public/images/logo.png"))
    default_group.save!
  end

end

