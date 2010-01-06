require 'flash_helper/application'
require 'flash_helper/application_helper'

ActionController::Base.send(:include, FlashHelper::ApplicationController)
ActionView::Base.send(:include, FlashHelper::ApplicationHelper)

