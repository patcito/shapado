if config.respond_to?(:gem)
  config.gem 'ruby-openid', :lib => 'openid', :version => '>=2.0.4'
else
  begin
    require 'openid'
    require 'mongomapper'
    require 'mm-search'
    require 'mm-files'
  rescue LoadError
    begin
      gem 'ruby-openid', '>=2.0.4'
    rescue Gem::LoadError
      puts "Install the ruby-openid gem to enable OpenID support"
    end
  end
end

config.to_prepare do
  OpenID::Util.logger = Rails.logger
end
