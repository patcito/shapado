class Announcement
  include MongoMapper::Document

  timestamps!
  key :_id, String

  key :message, String, :required => true
  key :starts_at, Timestamp, :required => true
  key :ends_at, Timestamp, :required => true

  key :only_anonymous, Boolean, :default => false

  key :group_id, String
  belongs_to :group

  validate :check_dates

  protected
  def check_dates
    if self.starts_at < Time.now.yesterday
      self.errors.add(:starts_at, "Starting date should be setted to a future date")
    end

    if self.ends_at <= self.starts_at
      self.errors.add(:ends_at, "Ending date should be greater than starting date")
    end
  end
end
