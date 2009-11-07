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
end

