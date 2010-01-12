class UserStat
  include MongoMapper::Document

  key :_id, String
  key :user_id, String
  belongs_to :user

  key :views_count, Float, :default => 0.0
  key :answer_tags, Array
  key :question_tags, Array
  key :expert_tags, Array

  key :last_activity_at, Hash
  key :activity_days, Hash

  timestamps!

  def activity_on(group, date)
    day = date.at_beginning_of_day
    last_day = self.last_activity_at[group.id]
    if last_day != day
      self.collection.update({:_id => self._id},
                             {:$set => {"last_activity_at.#{group.id}" => day}},
                              :upsert => true)
      if last_day
        if day.yesterday == last_day
          self.collection.update({:_id => self._id},
                                 {:$inc => {"activity_days.#{group.id}" => 1}},
                                  :upsert => true)
          Magent.push("/actors/judge", :on_activity, group.id, self.user_id)
        else
          reset_activity_days!(group)
        end
      end
    end
  end

  def reset_activity_days!(group)
    self.collection.update({:_id => self._id},
                           {:$set => {"activity_days.#{group.id}" => 0}},
                            :upsert => true)
  end

  def viewed!
    self.collection.update({:_id => self._id},
                           {:$inc => {:views_count => 1.0}},
                           :upsert => true)
  end

  def add_answer_tags(*tags)
    self.collection.update({:_id => self._id,
                            :answer_tags => {:$nin => tags} },
                           {:$pushAll => {:answer_tags => tags}},
                           {:upsert => true})
  end

  def add_question_tags(*tags)
    self.collection.update({:_id => self._id,
                            :question_tags => {:$nin => tags} },
                           {:$pushAll => {:question_tags => tags}},
                           {:upsert => true})
  end

  def add_expert_tags(*tags)
    self.collection.update({:_id => self._id,
                            :expert_tags => {:$nin => tags} },
                           {:$pushAll => {:expert_tags => tags}},
                           {:upsert => true})
  end
end
