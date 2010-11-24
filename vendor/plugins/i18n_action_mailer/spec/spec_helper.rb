$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require "rubygems"
gem 'actionmailer', '2.3.8'
require "action_mailer"
require 'i18n_action_mailer'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
end

TEMPLATE_PATH = File.join(File.dirname(__FILE__), "templates")
ActionMailer::Base.template_root = TEMPLATE_PATH
