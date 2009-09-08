require "action_mailer"

require File.join(File.dirname(__FILE__), '..', 'lib', "super_exception_notifier", "custom_exception_classes")
require File.join(File.dirname(__FILE__), '..', 'lib', "super_exception_notifier", "custom_exception_methods")

# Add this path to ruby load path
$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "hooks_notifier" unless defined?(HooksNotifier)
require "exception_notifier" unless defined?(ExceptionNotifier)
require "exception_notifiable" unless defined?(ExceptionNotifiable)
require "exception_notifier_helper" unless defined?(ExceptionNotifierHelper)
require "notifiable" unless defined?(Notifiable)

Object.class_eval do
  include Notifiable
end

#It appears that the view path is auto-added by rails... hmmm.
#if ActionController::Base.respond_to?(:append_view_path)
#  puts "view path before: #{ActionController::Base.view_paths}"
#  ActionController::Base.append_view_path(File.join(File.dirname(__FILE__), 'app', 'views','exception_notifiable'))
#  puts "view path After: #{ActionController::Base.view_paths}"
#end
