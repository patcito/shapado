# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def category_desc(key)
    I18n.t("categories.#{key}", :default => key.to_s.capitalize)
  end

  def category_options
    categories = Shapado::CATEGORIES
    categories = current_group.categories if current_group
    categories.collect do |category|
      [category_desc(category), category]
    end
  end

  def language_desc(langs)
    langs.map do |lang|
      I18n.t("languages.#{lang}", :default => lang)
    end.join(', ')
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
      tags = Question.tag_cloud({:group_id => current_group.id}.
                        merge(language_conditions.merge(language_conditions)))
    end

    return '' if tags.size <= 2

    max_size = options.delete(:max_size) || 35
    min_size = options.delete(:min_size) || 12

    tag_class = options.delete(:tag_class) || "tag"

    lowest_value, highest_value = tags.minmax_by { |tag| tag["count"].to_i }

    spread = (highest_value["count"] - lowest_value["count"])
    spread = 1 if spread == 0
    ratio = (max_size - min_size) / spread

    cloud = '<div class="tag_cloud">'
    tags.each do |tag|
      size = min_size + (tag["count"] - lowest_value["count"]) * ratio
      url = questions_path(:language => current_languages, :tags => tag["name"])
      cloud << "<span>#{link_to(tag["name"], url,
          :style => "font-size:#{size}px", :class => "#{tag_class}")}</span> "
    end
    cloud += "</div>"
    cloud
  end

  def country_flag(code, name)
    if code
      image_tag("flags/flag_#{code.downcase}.gif", :title => name, :alt => "")
    end
  end

  def markdown(txt)
    Maruku.new(sanitize(txt.to_s,
                        :tags => %w[b h1 h2 h3 i img sup sub strong br hr ul li ol em table pre code blockquote a],
                        :attributes => %w[href src title alt])).to_html
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

  def shapado_auto_link(text)
    auto_link(text, :all,  { "rel" => 'nofollow', :class => 'auto-link' })
  end

  def require_js(*files)
    content_for(:js) { javascript_include_tag(*files) }
  end

  def require_css(*files)
    content_for(:css) { stylesheet_link_tag(*files) }
  end

  def render_tag(tag)
    %@<span class="tag"><a href="#{questions_path(:language => current_languages, :tags => tag)}">#{@badge.token}</a></span>@
  end

  def class_for_question(question)
    klass = ""

    if question.answered
      klass << "answered"
    else
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
end

