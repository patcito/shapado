class Vote
  include MongoMapper::Document

  timestamps!

  key :_id, String
  key :value, Integer, :required => true

  key :user_id, String, :index => true
  belongs_to :user

  key :user_ip, String

  key :group_id, String, :required => true, :index => true
  belongs_to :group

  key :voteable_id, String
  key :voteable_type, String
  belongs_to :voteable, :polymorphic => true

  validates_presence_of :user_id, :voteable_id, :voteable_type
  validates_inclusion_of :value, :within => [1,-1]

  validate :should_be_unique
  validate :check_reputation
  validate :check_owner
  validate :check_voteable

  protected
  def should_be_unique
    vote = Vote.first( :voteable_type => self.voteable_type,
                       :voteable_id => self.voteable_id,
                       :user_id     => self.user_id )

    valid = (vote.nil? || vote.id == self.id)
    if !valid
      self.errors.add(:voteable, "You already voted this #{self.voteable_type}")
    end
  end

  def check_reputation
    if self.value > 0
      unless user.can_vote_up_on?(self.voteable.group)
        reputation = self.voteable.group.reputation_constrains["vote_up"]
        self.errors.add(:reputation, I18n.t("users.messages.errors.reputation_needed",
                                            :min_reputation => reputation,
                                            :action => I18n.t("users.actions.vote_up")))
        return false
      end
    else
      unless user.can_vote_down_on?(self.voteable.group)
        reputation = self.voteable.group.reputation_constrains["vote_down"]
        self.errors.add(:reputation, I18n.t("users.messages.errors.reputation_needed",
                                            :min_reputation => reputation,
                                            :action => I18n.t("users.actions.vote_down")))
        return false
      end
    end
    return true
  end

  def check_owner
    if self.voteable.user == self.user
      error = I18n.t(:flash_error, :scope => "votes.create") + " "
      error += I18n.t(self.voteable_type.downcase, :scope => "activerecord.models").downcase
      self.errors.add(:user, error)
      return false
    end
    return true
  end

  def check_voteable
    valid = true
    if self.voteable_type == "Question"
      valid = !self.voteable.closed
    elsif self.voteable_type == "Answer"
      valid = !self.voteable.question.closed
    end
    if !valid
      self.errors.add(:question, I18n.t("votes.model.messages.closed_question"))
    end
    return valid
  end
end
