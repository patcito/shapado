class Favorite
  include MongoMapper::Document

  key :_id, String
  key :group_id, String
  belongs_to :group

  key :user_id, String
  belongs_to :user

  key :question_id, String

  validate :should_be_unique

  protected
  def should_be_unique
    favorite = Favorite.find(:first, {:limit => 1,
                              :question_id => self.question_id,
                              :user_id     => self.user_id,
                              :group_id    => self.group_id
                             })

    valid = (favorite.nil? || favorite.id == self.id)
    if !valid
      self.errors.add(:favorite, "You already have this question as favorite")
    end
  end
end
