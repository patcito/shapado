atom_feed do |feed|
  title = "#{current_group.name} - #{t("activerecord.models.questions").capitalize} #{t("feeds.feed")}"

  tags = params[:tags]
  if tags && !tags.empty?
    title += " tags: #{tags.kind_of?(String) ? tags : tags.join(", ")}"
  end

  #if @langs_conds.kind_of?(Array)
  #  title += " languages: #{@langs_conds.join(", ")}"
  #elsif @lang_lands.kind_of?(String)
  #  title += " languages: #{@langs_conds}"
  #end

  feed.title(title)
  unless @questions.empty?
    feed.updated(@questions.first.updated_at)
  end

  for question in @questions
    next if question.nil? || question.updated_at.blank?
    feed.entry(question, :url => question_url(question)) do |entry|
      entry.title(question.title)
      entry.content(markdown(question.body), :type => 'html')
      entry.author do |author|
        author.name(question.user.login)
      end
    end
  end
end
