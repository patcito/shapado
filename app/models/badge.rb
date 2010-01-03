class Badge
  include MongoMapper::Document

  TYPES = %w[gold silver bronze]
  TOKENS = %w[service_medal merit_medal effort_medal popstar rockstar addict
              noob fanatic tutor critic commentator student famous_question
              favorite_question good_question good_answer inquirer troubleshooter]

  key :_id, String
  key :user_id, String, :required => true
  belongs_to :user

  key :group_id, String, :required => true
  belongs_to :group

  key :token, String, :required => true, :index => true
  key :type, String, :required => true

  key :source_id, String
  key :source_type, String
  belongs_to :source

  key :_type, String
  timestamps!

  validates_inclusion_of :type,  :within => TYPES
  validates_inclusion_of :token, :within => TOKENS

  def self.gold_badges
    self.find_all_by_type("gold")
  end

  def name
    @name ||= I18n.t("badges.#{self.token}", :default => self.token.titleize) if self.token
  end
end
