atom_feed do |feed|
  title = "#{AppConfig.domain} - #{t("activerecord.models.questions")}"

  if @category
    title += " category: #{@category}"
  end

  tags = params[:tags]
  if tags && !tags.empty?
    title += " tags: #{tags.kind_of?(String) ? tags : tags.join(", ")}"
  end

  if @languages
    title += " languages: #{@languages.join(", ")}"
  end

  feed.title(title)
  unless @questions.empty?
    feed.updated(@questions.first.updated_at)
  end

  for question in @questions
    next if question.updated_at.blank?
    feed.entry(question, :id =>"tag:#{question.id}") do |entry|
      entry.title(question.title)
      entry.content(markdown(question.body), :type => 'html')
      entry.updated(question.updated_at.strftime("%Y-%m-%dT%H:%M:%SZ"))
      entry.author do |author|
        author.name(question.user.login)
      end
    end
  end
end
