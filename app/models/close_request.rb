
class CloseRequest
  include MongoMapper::EmbeddedDocument
  REASONS = %w{dupe ot no_question not_relevant spam}

  key :_id, String
  key :reason, String, :in => REASONS

  key :user_id, String
  belongs_to :user

  key :comment, String

  validates_presence_of :user

  validate :should_be_unique
  validate :check_reputation

  protected
  def should_be_unique
    request = self._root_document.close_requests.detect{ |rq| rq.user_id == self.user_id }
    valid = (request.nil? || request.id == self.id)

    unless valid
      self.errors.add(:user, I18n.t("close_requests.model.messages.already_requested"))
    end

    valid
  end

  def check_reputation
    if ((self._root_document.user_id == self.user_id) && !self.user.can_vote_to_close_own_question_on?(self._root_document.group))
      reputation = self._root_document.group.reputation_constrains["vote_to_close_own_question"]
      self.errors.add(:reputation, I18n.t("users.messages.errors.reputation_needed",
                                          :min_reputation => reputation,
                                          :action => I18n.t("users.actions.vote_to_close_own_question")))
      return false
    end

    unless self.user.can_vote_to_close_any_question_on?(self._root_document.group)
      reputation = self._root_document.group.reputation_constrains["vote_to_close_any_question"]
            self.errors.add(:reputation, I18n.t("users.messages.errors.reputation_needed",
                                          :min_reputation => reputation,
                                          :action => I18n.t("users.actions.vote_to_close_any_question")))
      return false
    end

    true
  end
end
