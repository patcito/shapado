desc "Fix all"
task :fixall => [:environment, "fixdb:friends"] do
end

namespace :fixdb do
  desc "Friends"
  task :friends => :environment do
    User.all.each do |user|
      user.send(:create_friend_list)
      user.save(false)
    end
  end
end
