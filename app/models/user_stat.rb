class UserStat
  include MongoMapper::Document

  key :_id, String
  key :user_id, String
  belongs_to :user

  key :answer_tags, Array
  key :question_tags, Array
  key :expert_tags, Array

  key :tag_votes, Hash

  timestamps!

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

  def vote_on_tags(tags, inc = 1)
    opts = {}
    tags.each do |tag|
      opts["tag_votes.#{tag}"] = inc
    end
    self.collection.update({:_id => self._id},
                           {:$inc => opts},
                           {:upsert => true})
  end
end
