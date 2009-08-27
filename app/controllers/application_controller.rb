# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include CurrentTags
  protect_from_forgery

  before_filter :find_current_tags
  before_filter :set_locale

  protected
  def subdomain_url(subdomain, params = {})
    host = request.host.split("\.").last(2).join(".")
    request.protocol + "#{subdomain}." + host + request.port_string +
                                          url_for({:only_path =>true}.merge(params))
  end
  helper_method :subdomain_url

  def domain_url(params = {})
    host = request.host.split("\.").last(2).join(".")
    request.protocol + "://#{host}" + request.port_string+
                                          url_for({:only_path =>true}.merge(params))
  end
  helper_method :domain_url

  def find_current_tags
    @current_tags ||= begin
      metatags = Set.new
      metatags += request.subdomains

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
  end
  helper_method :scoped_conditions

  def language_conditions
    conditions = {}
    if @languages && !@languages.empty?
      conditions[:language] = {:$in => @languages}
    elsif current_user && !current_user.preferred_languages.empty?
      conditions[:language] = {:$in => current_user.preferred_languages }
    else
      conditions[:language] = I18n.locale.to_s.split("-").first
    end
    conditions
  end
  helper_method :language_conditions

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
      else
        'en'
    end
  end
  helper_method :find_valid_locale
end
