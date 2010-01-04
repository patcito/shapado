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
      [UsersWidget, BadgesWidget].each_with_index do |widget,pos|
        widget.create(:position => pos, :group_id => group.id)
      end
    end
  end
end
