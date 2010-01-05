namespace :fixdb do
  desc "Fix votes"
  task :votes => :environment do
    $stderr.puts "Updating #{Vote.count} votes..."
    Vote.all.each do |vote|
      vote.group = vote.voteable.group
      if vote.save(false)
        $stdout.print "."
      else
        $stdout.print "F"
      end

      $stdout.flush if rand(10) == 5
    end
  end

  desc "Fix groups"
  task :groups => :environment do
    $stderr.puts "Updating #{Group.count} groups..."
    Group.all.each do |group|
      GroupsWidget.create(:position => 0, :group_id => group.id) unless group.isolate || group.private
      UsersWidget.create(:position => 1, :group_id => group.id)
      BadgesWidget.create(:position => 2, :group_id => group.id)
    end
  end
end
