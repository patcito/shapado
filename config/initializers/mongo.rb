require 'mm-paginate'

MongoMapper.connection = Mongo::Connection.new(nil, nil, :auto_reconnect => true)
MongoMapper.database = "shapado-#{Rails.env}"

Dir.glob("#{RAILS_ROOT}/app/models/**/*") do |model_path|
  puts File.basename(model_path, ".rb").classify.constantize
end

MongoMapper.ensure_indexes!
