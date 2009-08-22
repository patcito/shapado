# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def category_desc(key)
    I18n.t("categories.#{key}", :default => key.capitalize)
  end

  def category_options
    Shapado::CATEGORIES.collect do |category|
      [category_desc(category), category]
    end
  end
end
