# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include CurrentTags
  protect_from_forgery

  before_filter :find_current_tags
  before_filter :set_locale

  protected
  def find_current_tags
    @current_tags ||= begin
      tags = []
      if params[:tags]
        tags += params[:tags].kind_of?(Array) ? params[:tags] : [params[:tags]]
      end
      if current_tag.present?
        tags += [current_tag]
      end
      tags
    end
  end
  alias :current_tags :find_current_tags

  def scoped_conditions(conditions = {})

    if current_tags && !current_tags.empty?
      conditions.deep_merge!({:tags => current_tags})
    end

    if current_user && !current_user.preferred_languages.empty?
      conditions.deep_merge!({:language => {:$in => current_user.preferred_languages }})
    else
      conditions.deep_merge!({:language => I18n.locale.to_s})
    end

    conditions
  end

  def available_locales; AVAILABLE_LOCALES; end

  def set_locale
    locale = 'en'
    if logged_in?
      locale = current_user.language
    else
      if request.env['HTTP_ACCEPT_LANGUAGE'] =~ /^(\w\w)/
        lang = $1
        case lang
        when 'es'
          locale = 'es-AR'
        end
      end
    end

    I18n.locale = locale
  end
end
