require 'mm-paginate'

MongoMapper.connection = Mongo::Connection.new(nil, nil, :auto_reconnect => true)
MongoMapper.database = "shapado-#{Rails.env}"

Dir.glob("#{RAILS_ROOT}/app/models/**/*.rb") do |model_path|
  File.basename(model_path, ".rb").classify.constantize
end

MongoMapper.ensure_indexes!

Dir.glob("#{RAILS_ROOT}/app/javascripts/**/*.js") do |js_path|
  code = File.read(js_path)
  name = File.basename(js_path, ".js")

  # HACK: looks like ruby driver doesn't support this
  MongoMapper.database.eval("db.system.js.save({_id: '#{name}', value: #{code}})")
end
