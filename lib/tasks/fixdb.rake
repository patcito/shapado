desc "Fix all"
task :fixall => [:environment, "fixdb:pages", "fixdb:comment_voteable"] do
end

namespace :fixdb do
  task :pages => :environment do
    Group.all(:language.nin => [nil, ""]).each do |g|
      g.pages.destroy_all(:language.ne => g.language)
    end
  end

  desc "initialize values to become comments as voteable"
  task :comment_voteable => :environment do
    Comment.collection.update({:_type => "Comment"}, {:$set => {:votes_count => 0,
                                                                :votes_average => 0}},
                               :upsert => true,
                               :safe => true,
                               :multi => true)
  end

  task :comments => :environment do
    Comment.find_each(:group_id => nil) do |comment|
      group_id = comment.commentable.group_id
      comment.set({:group_id => group_id})
    end
  end
end

