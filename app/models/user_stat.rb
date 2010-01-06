class UserStat
  include MongoMapper::Document

  key :_id, String
  key :user_id, String
  belongs_to :user

  key :views_count, Float, :default => 0.0
  key :answer_tags, Array
  key :question_tags, Array
  key :expert_tags, Array

  timestamps!

  def visited_on(time)
    self.collection.update({:_id => self._id,
                            visits_key(time) => {:$ne => time.mday}},
                           {:$push => {visits_key(time) => time.mday}},
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
                           {:$pushAll => {:question_tags => tags}},
                           {:upsert => true})
  end

  private
  def visits_key(time)
    "visits_#{time.year}.#{time.month}"
  end
end
