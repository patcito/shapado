class Report
  attr_reader :group, :since
  attr_reader :questions, :answers, :users, :badges, :votes

  def initialize(group, since = Time.now.yesterday)
    @group = group
    @since = since

    @questions = group.questions.count(:created_at => {:$gt => since})
    @answers = group.answers.count(:created_at => {:$gt => since})

    @users = User.count("membership_list.#{group.id}.reputation" => {:$exists => true})
    @badges = group.badges.count(:created_at => {:$gt => since})

    @votes = group.votes.count(:created_at => {:$gt => since})
  end
end
