class Flag
  include MongoMapper::EmbeddedDocument
  REASONS = ["spam", "offensive", "attention"]
  key :reason, String, :required => true, :default => "spam"

  key :_id, String
  key :user_id, String
  belongs_to :user

  validates_presence_of :user
  validates_inclusion_of :reason, :within => REASONS

  validate :should_be_unique
  validate :check_reputation

  protected
  def should_be_unique
    request = self._root_document.flags.detect{ |rq| rq.user_id == self.user_id }
    valid = (request.nil? || request.id == self.id)

    if !valid
      self.errors.add(:user, I18n.t("flags.model.messages.already_requested",
                                    :model => I18n.t("activerecord.models.#{@resource.class.to_s.tableize.singularize}")))
    end
    valid
  end

  def check_reputation
    if ((self._root_document.user_id == self.user_id) && !self.user.can_flag_on?(self._root_document.group))
      reputation = self._root_document.group.reputation_constrains["flag"]
      self.errors.add(:reputation, I18n.t("users.messages.errors.reputation_needed",
                                          :min_reputation => reputation,
                                          :action => I18n.t("users.actions.flag")))
      return false
    end
    true
  end
end
