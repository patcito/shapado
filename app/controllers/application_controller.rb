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

  before_filter :find_current_tags
  before_filter :set_locale

  protected
  def access_denied
    raise AccessDenied
  end

  def find_current_tags
    @current_tags ||= begin
      metatags = Set.new
      metatags += request.subdomains
      metatags.delete("www")

      @languages ||=  begin
                        languages = []
                        metatags.each do |tag|
                          if AVAILABLE_LANGUAGES.include?(tag)
                            languages << tag
                            metatags.delete(tag)
                          end
                          @category ||= Shapado::CATEGORIES.detect {|e| e == tag}
                        end
                        languages
                      end

      if params[:tags]
        metatags += params[:tags].kind_of?(Array) ? params[:tags] : [params[:tags]]
      end
      metatags
    end
  end
  alias :current_tags :find_current_tags

  def scoped_conditions(conditions = {})
    unless current_tags.empty?
      conditions.deep_merge!({:_metatags => current_tags.to_a})
    end
    conditions.deep_merge!(language_conditions)
    conditions.deep_merge!(categories_conditions)
  end
  helper_method :scoped_conditions

  def language_conditions
    conditions = {}
    if @languages && !@languages.empty?
      conditions[:language] = { :$in => @languages}
    elsif current_user && !current_user.preferred_languages.empty?
      conditions[:language] = { :$in => current_user.preferred_languages}
    elsif params[:language]
      langs = params[:language].kind_of?(Array) ? params[:language] : [params[:language]]
      conditions[:language] = {:$in => langs}
    else
      conditions[:language] = {:$in => [I18n.locale.to_s.split("-").first]}
    end
    conditions
  end
  helper_method :language_conditions

  def categories_conditions
    conditions = {}
    if logged_in? && !current_user.categories.blank?
      conditions[:category] = {:$in => current_user.categories}
    end
    conditions
  end
  helper_method :categories_conditions

  def categories_required
    if logged_in? && current_user.categories.blank?
      flash[:error] = t("not_categories_warn", :scope => "views.application")
      redirect_to :controller => "users", :action => "edit"
    end
  end

  def available_locales; AVAILABLE_LOCALES; end

  def set_locale
    locale = 'en'
    if logged_in?
      locale = current_user.language
    elsif params[:lang] =~ /^(\w\w)/
      locale = find_valid_locale($1)
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
      "#{@page_title} - #{AppConfig.application_name}: #{t("views.layout.title")}"
    else
      "#{AppConfig.application_name} - #{t("views.layout.title")}"
    end
  end
  helper_method :page_title

  def add_feeds_url(url, title="atom")
    @feed_urls = [] unless @feed_urls
    @feed_urls << [title, url]
  end

  def moderator_required
    unless current_user.moderator?
      access_denied
#       flash[:error] = t("views.layout.permission_denied")
#       redirect_to root_path
    end
  end
end
