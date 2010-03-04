desc "Fix all"
task :fixall => [:environment, "fixdb:friends", "fixdb:activity_notifs", "fixdb:custom_settings"] do
end

namespace :fixdb do
  desc "Friends"
  task :friends => :environment do
    User.all.each do |user|
      user.send(:create_friend_list)
      user.save(:validate => false)
    end
  end

  desc "Notifications"
  task :activity_notifs => :environment do
    User.find_each(:fields => [:_id]) do |user|
      User.set(user.id, {"notification_opts.activities" => "1", "notification_opts.reports" => "1"})
    end
  end

  desc "Update custom settings"
  task :custom_settings => :environment do
    $stderr.puts "Updating #{Group.count} groups..."
    Group.all.each do |g|
      g.has_custom_ads = true
      g.has_custom_analytics = true
      g.has_custom_html = true
      g.has_custom_js = true
      g.save
    end
  end
end
