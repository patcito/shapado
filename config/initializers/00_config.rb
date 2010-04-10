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


REPUTATION_CONSTRAINS = {"vote_up" => 15, "flag" => 15, "post_images" => 15,
"comment" => 50, "delete_own_comments" => 50, "vote_down" => 100,
"create_new_tags" => 100, "post_whithout_limits" => 100, "edit_wiki_post" => 100,
"remove_advertising" => 200, "vote_to_open_own_question" => 250, "vote_to_close_own_question" => 250,
"retag_others_questions" => 500, "delete_comments_on_own_questions" => 750,
"edit_others_posts" => 2000, "view_offensive_counts" => 2000, "vote_to_open_any_question" => 3000,
"vote_to_close_any_question" => 3000, "delete_closed_questions" => 10000, "moderate" => 10000}

REPUTATION_REWARDS = YAML.load_file(RAILS_ROOT+"/config/default_reputation.yml")


REST_AUTH_SITE_KEY         = AppConfig.rest_auth_key
REST_AUTH_DIGEST_STRETCHES = AppConfig.rest_auth_digest_stretches

ActionController::Base.session_options[:domain] = ".#{AppConfig.domain}"
ActionController::Base.session_options[:key] = AppConfig.session_key
ActionController::Base.session_options[:secret] = AppConfig.session_secret

ActionMailer::Base.default_url_options[:host] = AppConfig.domain

AppConfig.enable_facebook_auth = File.exist?(RAILS_ROOT+"/config/facebooker.yml")

if File.exist?(RAILS_ROOT+"/public/version.txt")
  AppConfig.version = File.read(RAILS_ROOT+"/public/version.txt")
end
