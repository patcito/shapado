class ViewsCount
  include MongoMapper::Document
  timestamps!

  key :_id, String

  def self.cleanup!
    ViewsCount.delete_all(:created_at.lt => 8.days.ago)
  end
end
