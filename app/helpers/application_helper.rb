# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def with_facebook?
    return true if current_group.share.fb_active

    if request.host =~ Regexp.new("#{AppConfig.domain}$", Regexp::IGNORECASE)
      AppConfig.facebook["activate"]
    else
      false
    end
  end

  def context_panel_ads(group)
    if AppConfig.enable_adbard && request.domain == AppConfig.domain &&
        !Adbard.find_by_group_id(current_group.id)
      adbard = "<!--Ad Bard advertisement snippet, begin -->
        <script type='text/javascript'>
        var ab_h = '#{AppConfig.adbard_host_id}';
        var ab_s = '#{AppConfig.adbard_site_key}';
        </script>
        <script type='text/javascript' src='http://cdn1.adbard.net/js/ab1.js'></script>
        <!--Ad Bard, end -->"
    else
      adbard = ""
    end
    if group.has_custom_ads == true
      ads = []
      Ad.find_all_by_group_id_and_position(group.id,'context_panel').each do |ad|
        ads << ad.code
      end
      ads << adbard
      return ads.join unless ads.empty?
    end
  end

  def header_ads(group)
    if group.has_custom_ads
      ads = []
      Ad.find_all_by_group_id_and_position(group.id,'header').each do |ad|
        ads << ad.code
      end
      return ads.join  unless ads.empty?
    end
  end

  def content_ads(group)
    if group.has_custom_ads
      ads = []
      Ad.find_all_by_group_id_and_position(group.id,'content').each do |ad|
        ads << ad.code
      end
      return ads.join  unless ads.empty?
    end
  end

  def footer_ads(group)
    if group.has_custom_ads
      ads = []
      Ad.find_all_by_group_id_and_position(group.id,'footer').each do |ad|
        ads << ad.code
      end
      return ads.join  unless ads.empty?
    end
  end

  def language_desc(langs)
    langs.map do |lang|
      I18n.t("languages.#{lang}", :default => lang).capitalize
    end.join(', ')
  end

  def language_select(f, question, opts = {})
    selected = if question.new?
      logged_in? ? current_user.main_language : question.language
    else
      question.language
    end
    languages = logged_in? ? current_user.preferred_languages : AVAILABLE_LANGUAGES

    f.select :language, languages_options(languages), {:selected => selected}, {:class => "select"}.merge(opts)
  end

  def languages_options(languages=nil, current_languages = [])
    languages = AVAILABLE_LANGUAGES-current_languages if languages.blank?
    locales_options(languages)
  end

  def locales_options(languages=nil)
    languages = AVAILABLE_LOCALES if languages.blank?
    languages.collect do |lang|
      [language_desc(lang), lang]
    end
  end


  def tag_cloud(tags = [], options = {})
    if tags.empty?
      tags = Question.tag_cloud({:group_id => current_group.id, :banned => false}.
                        merge(language_conditions.merge(language_conditions)))
    end

    return '' if tags.size <= 2

    # Sizes: xxs xs s l xl xxl
    css = {1 => "xxs", 2 => "xs", 3 => "s", 4 => "l", 5 => "xl" }
    max_size = 5
    min_size = 1

    tag_class = options.delete(:tag_class) || "tag"

    lowest_value = tags.min { |a, b| a["count"].to_i <=> b["count"].to_i }
    highest_value = tags.max { |a, b| a["count"].to_i <=> b["count"].to_i }

    spread = (highest_value["count"] - lowest_value["count"])
    spread = 1 if spread == 0
    ratio = (max_size - min_size) / spread

    cloud = '<div class="tag_cloud">'
    tags.each do |tag|
      next if tag["count"].kind_of?(String)
      size = min_size + (tag["count"] - lowest_value["count"]) * ratio
      url = url_for(:controller => "questions", :action => "index", :tags => tag["name"])
      cloud << "<span>#{link_to(tag["name"], url, :class => "#{tag_class} #{css[size.round]}")}</span> "
    end
    cloud += "</div>"
    cloud
  end

  def country_flag(code, name)
    if code
      image_tag("flags/flag_#{code.downcase}.gif", :title => name, :alt => "")
    end
  end

  def markdown(txt, options = {})
    raw = options.delete(:raw)
    body = render_page_links(txt.to_s, options)
    txt = if raw
      (defined?(RDiscount) ? RDiscount.new(body) : Maruku.new(body)).to_html
    else
      (defined?(RDiscount) ? RDiscount.new(body, :smart, :strict) : Maruku.new(sanitize(body))).to_html
    end

    if options[:sanitize] != false
      txt = defined?(Sanitize) ? Sanitize.clean(txt, SANITIZE_CONFIG) : sanitize(txt)
    end
    txt
  end

  def render_page_links(text, options = {})
    group = options[:group]
    group = current_group if group.nil?
    in_controller = respond_to?(:logged_in?)

    text.gsub!(/\[\[([^\,\[\'\"]+)\]\]/) do |m|
      link = $1.split("|", 2)
      page = Page.by_title(link.first, {:group_id => group.id, :select => [:title, :slug]})


      if page.present?
        %@<a href="/pages/#{page.slug}" class="page_link">#{link[1] || page.title}</a>@
      else
        %@<a href="/pages/#{link.first.parameterize.to_s}?create=true&title=#{link.first}" class="missing_page">#{link.last}</a>@
      end
    end

    return text if !in_controller

    text.gsub(/%(\S+)%/) do |m|
      case $1
        when 'site'
          group.domain
        when 'site_name'
          group.name
        when 'current_user'
          if logged_in?
            link_to(current_user.login, user_path(current_user))
          else
            "anonymous"
          end
        when 'hottest_today'
          question = Question.first(:activity_at.gt => Time.zone.now.yesterday, :order => "hotness desc, views_count asc", :group_id => group.id, :select => [:slug, :title])
          if question.present?
            link_to(question.title, question_path(question))
          end
        else
          m
      end
    end
  end

  def format_number(number)
    if number < 1000
      number.to_s
    elsif number >= 1000 && number < 1000000
      "%.01fK" % (number/1000.0)
    elsif number >= 1000000
      "%.01fM" % (number/1000000.0)
    end
  end

  def class_for_number(number)
    if number >= 1000 && number < 10000
      "medium_number"
    elsif number >= 10000
      "big_number"
    elsif number < 0
      "negative_number"
    end
  end

  def shapado_auto_link(text, options = {})
    text = auto_link(text, :all,  { "rel" => 'nofollow', :class => 'auto-link' })
    if options[:link_users]
      text = TwitterRenderer.auto_link_usernames_or_lists(text, :username_url_base => "#{users_path}/", :suppress_lists => true)
    end

    text
  end

  def require_js(*files)
    content_for(:js) { javascript_include_tag(*files) }
  end

  def require_css(*files)
    content_for(:css) { stylesheet_link_tag(*files) }
  end

  def render_tag(tag)
    %@<span class="tag"><a href="#{questions_path(:tags => tag)}">#{@badge.token}</a></span>@
  end

  def class_for_question(question)
    klass = ""

    if question.accepted
      klass << "accepted"
    elsif !question.answered
      klass << "unanswered"
    end

    if logged_in?
      if current_user.is_preferred_tag?(current_group, *question.tags)
        klass << " highlight"
      end

      if current_user == question.user
        klass << " own_question"
      end
    end

    klass
  end

  def googlean_script(analytics_id, domain)
    "<script type=\"text/javascript\">
       var _gaq = _gaq || [];
       _gaq.push(['_setAccount', '#{analytics_id}']);
       _gaq.push(['_trackPageview'],['_setDomainName', '#{domain}']);

       (function() {
         var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
         ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
         (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(ga);
       })();
    </script>"
  end

  def logged_out_language_filter
    custom_lang = session["user.language_filter"]
    case custom_lang
    when "any"
      languages = "any"
    else
      languages = session["user.language_filter"] || I18n.locale.to_s.split('-').first
    end
    languages
  end

  def clean_seo_keywords(tags, text = "")
    if tags.size < 5

      text.scan(/(\S+)/) do |s|
        word = s.to_s.downcase
        if word.length > 3 && !tags.include?(word)
          tags << word
        end

        break if tags.size >= 5
      end
    end

    tags.join(', ')
  end

  def current_announcements(hide_time = nil)
    conditions = {:starts_at.lte => Time.zone.now.to_i,
                  :ends_at.gte => Time.zone.now.to_i,
                  :order => "starts_at desc",
                  :group_id.in => [current_group.id, nil]}
    if hide_time
      conditions[:updated_at] = {:$gt => hide_time}
    end

    if logged_in?
      conditions[:only_anonymous] = false
    end

    Announcement.all(conditions)
  end

  def top_bar_links
    top_bar = current_group.custom_html.top_bar
    return [] if top_bar.blank?

    top_bar.split("\n").map do |line|
      render_page_links(line.strip)
    end
  end

  def include_latex
    if current_group.enable_latex
      require_js domain_url(:custom => current_group.domain)+'/javascripts/jsMath/easy/load.js'
    end
  end
end

