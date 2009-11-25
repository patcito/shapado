namespace :fixdb do
  task :hotness => :environment do
    Question.all.each do |q|
      q.hotness = q.votes_count + q.answers_count
      q.save
    end
  end

  task :groups_support => :environment do
    default_group = Group.find_by_name(AppConfig.application_name)
    Question.all.each do |q|
      unless q.group_id
        q.group_id = default_group.id
        q.save
      end
    end

    Answer.all.each do |a|
      unless a.group_id
        a.group_id = default_group.id
        a.save
      end
    end

    User.collection.find.each do |u|
      if u["preferred_tags"].kind_of?(Array)
        User.collection.update({:_id => u["_id"]},
            {:$set => {"preferred_tags" => {default_group.id => u["preferred_tags"]}}},
             :upsert => true, :safe => true)
      end

      if u["reputation"].kind_of?(Integer) || u["reputation"].kind_of?(Float)
        User.collection.update({:_id => u["_id"]},
            {:$set => {"reputation" => {default_group.id => u["reputation"]}}},
             :upsert => true)
      end
    end
  end

  task :cleanup_documents => :environment do
    Question.collection.find.each do |q|
      if q["_metatags"]
        Question.collection.update({:_id => q["_id"]},
                                {:$set => {"_metatags"=>nil}}, :safe => true)
      end
    end
  end

  task :foreign_keys => :environment do
    def fix_model(model, keys)
      model.collection.find.each do |doc|
        keys.each do |key|
          id = doc[key.to_s]
          if id.kind_of? String
            print "."
            if obj_id = Mongo::ObjectID.from_string(id)
              model.collection.update({:_id => doc["_id"]},
                                {:$set => {key.to_s=>obj_id}}, :safe => true)
            end
          end
        end
      end
    end
    print "fixing Question"
    fix_model(Question, [:user_id, :group_id])
    print "\nfixing Answer"
    fix_model(Answer, [:user_id, :question_id, :group_id, :parent_id])
    print "\nfixing Logo"
    fix_model(Logo, [:group_id])
    print "\nfixing Vote"
    fix_model(Vote, [:user_id, :voateable_id])
    print "\nfixing Flag"
    fix_model(Flag, [:user_id, :flaggeable_id])
    print "\nfixing Group"
    fix_model(Group, [:owner_id])
    print "\nfixing Member"
    fix_model(Member, [:user_id, :group_id]) 
    print "\nfixing Favorite"
    fix_model(Favorite, [:user_id, :group_id, :question_id])
    print "\nfinish"
  end
end

