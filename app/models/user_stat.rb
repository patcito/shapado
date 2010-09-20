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
    self.collection.update({:_id => self.id},
                              { :$addToSet => { :answer_tags => { :$each => tags }}})
  end

  def add_question_tags(*tags)
    self.collection.update({:_id => self.id},
                              { :$addToSet => { :question_tags => { :$each => tags }}})
  end

  def add_expert_tags(*tags)
    self.collection.update({:_id => self.id},
                              { :$addToSet => { :expert_tags => { :$each => tags }}})
  end

  def vote_on_tags(tags, inc = 1)
    opts = {}
    tags.each do |tag|
      opts["tag_votes.#{tag}"] = inc
    end
    self.increment(opts)
  end
end
