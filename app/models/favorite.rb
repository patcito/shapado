class Favorite
  include MongoMapper::Document

  key :_id, String
  key :group_id, String, :index => true
  belongs_to :group

  key :user_id, String, :index => true
  belongs_to :user

  key :question_id, String
  belongs_to :question

  validate :should_be_unique # FIXME

  protected
  def should_be_unique
    favorite = Favorite.first({:question_id => self.question_id,
                                :user_id     => self.user_id,
                                :group_id    => self.group_id
                               })

    valid = (favorite.nil? || favorite.id == self.id)
    if !valid
      self.errors.add(:favorite, "You already have this question as favorite")
    end
  end
end
