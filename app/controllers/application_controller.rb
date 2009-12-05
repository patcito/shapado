# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include ExceptionNotifiable
  include SuperExceptionNotifier
  include ExceptionNotifierHelper
  self.error_layout = 'error'

  include AuthenticatedSystem
  include Subdomains
  local_addresses.clear

  protect_from_forgery

  before_filter :check_group_access
  before_filter :find_languages
  before_filter :set_locale
  layout :set_layout

  protected
  def access_denied
    store_location
    raise AccessDenied
  end

  def check_group_access
    if current_group.private && (!logged_in? || !current_user.user_of?(current_group))
      access_denied
    end
  end

  def set_layout
    if current_group.isolate
      'group'
    else
      'application'
    end
  end

  def current_group
    subdomains = request.subdomains
    subdomains.delete("www") if request.host == "www.#{AppConfig.domain}"

    @current_group ||= Group.find(:first, :state => "active", :domain => request.host) ||
                       Group.find_by_name(AppConfig.application_name)

    @current_group
  end
  helper_method :current_group

  def current_tags
    if params[:tags].kind_of?(String)
      @current_tags ||= params[:tags].split("+")
    elsif params[:tags].kind_of?(Array)
      @current_tags ||= params[:tags]
    else
      @current_tags || []
    end
  end
  helper_method :current_tags

  def current_languages
    @current_languages = find_languages.join("+")
  end
  helper_method :current_languages

  def find_languages
    @languages ||= begin
      if languages = current_group.language
        languages = [languages]
      else
        if params[:language] && !params[:language].empty?
          languages = params[:language].split('+').select{ |lang| AVAILABLE_LANGUAGES.include?(lang) }
        elsif current_user && !current_user.preferred_languages.empty?
          languages = current_user.preferred_languages
        elsif params[:language]
          languages = params[:language].kind_of?(Array) ? params[:language] : [params[:language]]
        else
          languages = [I18n.locale.to_s.split("-").first]
        end
      end
      languages
    end
  end

  def language_conditions
    conditions = {}
    conditions[:language] = { :$in => find_languages}
    conditions
  end
  helper_method :language_conditions

  def scoped_conditions(conditions = {})
    unless current_tags.empty?
      conditions.deep_merge!({:tags => {:$all => current_tags}})
    end
    conditions.deep_merge!({:group_id => current_group.id})
    conditions.deep_merge!(language_conditions)
  end
  helper_method :scoped_conditions

  def available_locales; AVAILABLE_LOCALES; end

  def set_locale
    locale = 'en'
    if logged_in?
      locale = current_user.language
    elsif params[:lang] =~ /^(\w\w)/
      locale = find_valid_locale($1)
      puts locale
    else
      if request.env['HTTP_ACCEPT_LANGUAGE'] =~ /^(\w\w)/
        locale = find_valid_locale($1)
      end
    end

    I18n.locale = locale
  end

  def find_valid_locale(lang)
    case lang
      when /^es/
        'es-AR'
      when /^pt/
        'pt-PT'
      when "fr"
        'fr'
      else
        'en'
    end
  end
  helper_method :find_valid_locale

  def set_page_title(title)
    @page_title = title
  end

  def page_title
    if @page_title
      if current_group.name == AppConfig.application_name
        "#{@page_title} - #{AppConfig.application_name}: #{t("layouts.application.title")}"
      else
        if current_group.isolate
          "#{@page_title} - #{current_group.name} #{current_group.legend}"
        else
          "#{@page_title} - #{current_group.name}@#{AppConfig.application_name}: #{current_group.legend}"
        end
      end
    else
      if current_group.name == AppConfig.application_name
        "#{AppConfig.application_name} - #{t("layouts.application.title")}"
      else
        if current_group.isolate
          "#{current_group.name} - #{current_group.legend}"
        else
          "#{current_group.name}@#{AppConfig.application_name} - #{current_group.legend}"
        end
      end
    end
  end
  helper_method :page_title

  def add_feeds_url(url, title="atom")
    @feed_urls = [] unless @feed_urls
    @feed_urls << [title, url]
  end

  def admin_required
    unless current_user.admin?
      access_denied
    end
  end

  def moderator_required
    unless current_user.mod_of?(current_group)
      access_denied
    end
  end
end
