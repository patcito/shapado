atom_feed do |feed|
  feed.title("#{h(@question.title)} - #{current_group.name}")
  feed.updated(@question.updated_at)

  feed.entry(@question, :url => question_url(@question), :id =>"tag:#{@question.id}") do |entry|
    entry.title(h(@question.title))
    entry.content(markdown(@question.body), :type => 'html')
    entry.updated(@question.updated_at.strftime("%Y-%m-%dT%H:%M:%SZ"))
    entry.author do |author|
      author.name(h(@question.user.login))
    end
  end

  for answer in @answers
    next if answer.updated_at.blank?
    feed.entry(answer, :url => question_answer_url(@question, answer)) do |entry|
      entry.title("answer by #{h(answer.user.login)} for #{h(@question.title)}")
      entry.content(markdown(answer.body), :type => 'html')
      entry.author do |author|
        author.name(h(answer.user.login))
      end
    end
  end
end
