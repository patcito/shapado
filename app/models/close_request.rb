
class CloseRequest
  include MongoMapper::EmbeddedDocument
  TYPES = %w{dupe ot no_question not_relevant spam}

  key :_id, String
  key :reason, String, :in => TYPES

  key :user_id, String
  belongs_to :user

  validate :should_be_unique
  protected
  def should_be_unique
    request = self._root_document.close_requests.detect{ |rq| rq.user_id == self.user_id }
    valid = (request.nil? || request.id == self.id)
    unless valid
      self.errors.add(:user, "You have already requested to close this question")
    end
    return valid
  end
end
