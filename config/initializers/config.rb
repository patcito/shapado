require 'ostruct'

config_file = "/etc/shapado.yml"
if !File.exist?(config_file)
  config_file = RAILS_ROOT+"/config/shapado.yml"
end

if !File.exist?(config_file)
  raise StandardError,  "Config file was not found"
end

options = YAML.load_file(config_file)
if !options[RAILS_ENV]
  raise "'#{RAILS_ENV}' was not found in #{config_file}"
end

AppConfig = OpenStruct.new(options[RAILS_ENV])

# check config
begin
  known_options = YAML.load_file(RAILS_ROOT+"/config/shapado.sample.yml")[RAILS_ENV]
  known_options.each do |k, v|
    if AppConfig.send(k).nil?
      $stderr.puts "Warning: missing config option: '#{k}'"
    end
  end
end

reputation_config_file = "/etc/shapado.reputation.yml"
if !File.exist?(reputation_config_file)
  reputation_config_file = RAILS_ROOT+"/config/reputation.yml"
end

if !File.exist?(reputation_config_file)
  raise StandardError,  "Reputation Config file was not found"
end


REPUTATION_CONF = YAML.load_file(reputation_config_file)


REST_AUTH_SITE_KEY         = AppConfig.rest_auth_key
REST_AUTH_DIGEST_STRETCHES = AppConfig.rest_aut_digest_stretches

ActionController::Base.session_options[:domain] = ".#{AppConfig.domain}"
ActionController::Base.session_options[:key] = AppConfig.session_key
ActionController::Base.session_options[:secret] = AppConfig.session_secret
