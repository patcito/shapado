require 'ostruct'

config_file = RAILS_ROOT+"/config/shapado.yml"
options = YAML.load_file(config_file)
if !options[RAILS_ENV]
  raise "#{RAILS_ENV} was not found in #{config_file}"
end
AppConfig = OpenStruct.new(options)
AppConfig.domain = options[RAILS_ENV]["domain"]
[:development, :production, :test].each {|f| AppConfig.delete_field(f)}
ActionController::Base.session_options[:domain] = ".#{AppConfig.domain}"
