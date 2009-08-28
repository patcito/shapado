require 'ostruct'

config_file = RAILS_ROOT+"/config/shapado.yml"
options = YAML.load_file(config_file)
if !options[RAILS_ENV]
  raise "#{RAILS_ENV} was not found in #{config_file}"
end
AppConfig = OpenStruct.new(options[RAILS_ENV])
ActionController::Base.session_options[:domain] = ".#{AppConfig.domain}"

