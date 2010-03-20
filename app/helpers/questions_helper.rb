module QuestionsHelper
  def microblogging_message(question)
    message = "#{h(question.title)}"
    message += " "
    message +=  question_path(question, :only_path =>false)
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
        url = "http://www.facebook.com/sharer.php?u=#{microblogging_message(question)}&t=TEXTO"
    end
    url
  end
end
