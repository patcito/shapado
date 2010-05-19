
class ReputationEvent
  include MongoMapper::EmbeddedDocument
  key :_id, String
  key :time, Time
  key :event, String
  key :reputation, Float
  key :delta, Float
end

class ReputationStat
  include MongoMapper::Document
  key :_id, String

  many :events, :class_name => "ReputationEvent"

  key :user_id, String
  belongs_to :user

  key :group_id, String
  belongs_to :group
end
