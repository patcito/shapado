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

  def language_desc(lang)
    I18n.t("languages.#{lang}", :default => lang)
  end

  def languages_options(languages=nil, current_languages = [])
    languages = AVAILABLE_LANGUAGES-(current_languages||[]) if languages.blank?
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
                        merge(language_conditions.merge(categories_conditions)))
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
      url = questions_path(:category => current_category, :tags => tag["name"])
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
    Maruku.new(sanitize(txt.to_s, :tags => %w[b h1 h2 h3 i img sup sub strong br hr ul li ol em table pre code blockquote a], :attributes => %w[href src title alt])).to_html
  end
end

