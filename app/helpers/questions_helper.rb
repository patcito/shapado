module QuestionsHelper
  def microblogging_message(question)
    message = "#{h(question.title)}"
    message += " "
    message += question_path(current_languages, question, :only_path =>false)
    message
  end

  def share_url(question, service)
    url = ""
    case service
      when :twitter
        url = "http://twitter.com/?status=#{microblogging_message(question)}"
      when :identica
        url = "http://identi.ca/notice/new?status_textarea=#{microblogging_message(question)}"
      when :facebook
        url = "http://www.facebook.com/sharer.php?u=#{question_path(current_languages, question, :only_path =>false)}&t=TEXTO"
    end
    URI.escape(url)
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
end
