require 'mm-paginate'

db_file = File.join(Rails.root, "/config/database.yml")
ok = false
if File.exist?(db_file)
  puts ">> Loading db config from #{db_file} in #{Rails.env} environment..."
  db_config = YAML.load_file(db_file)

  if db_config.include?(Rails.env) && (mongo_config = db_config[Rails.env])
    MongoMapper.connection = Mongo::Connection.new(mongo_config['host'],
                                                   mongo_config['port'] || 27017,
                                                  :logger => Rails.logger)
    MongoMapper.database = mongo_config['database']
    ok = true
  end
end

if !ok
  MongoMapper.connection = Mongo::Connection.new(nil, nil, :auto_reconnect => true, :logger => Rails.logger)
  MongoMapper.database = "shapado-#{Rails.env}"
end


MongoMapperExt.init

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    MongoMapper.connection.connect_to_master if forked
  end
end

Dir.glob("#{RAILS_ROOT}/app/models/**/*.rb") do |model_path|
  File.basename(model_path, ".rb").classify.constantize
end


Dir.glob("#{RAILS_ROOT}/app/javascripts/**/*.js") do |js_path|
  code = File.read(js_path)
  name = File.basename(js_path, ".js")

  # HACK: looks like ruby driver doesn't support this
  MongoMapper.database.eval("db.system.js.save({_id: '#{name}', value: #{code}})")
end

require 'support/versionable'
