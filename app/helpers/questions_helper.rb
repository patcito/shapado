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
      when :identica
        url = "http://identi.ca/notice/new?status_textarea=#{microblogging_message(question)}"
      when :shapado
        url = "http://shapado.com?"
      when :twitter
        url = "http://twitter.com/?status=#{microblogging_message(question)}"
      when :facebook
        url = "http://www.facebook.com/sharer.php?u=#{microblogging_message(question)}&t=TEXTO"
      when :linkedin
        url = "http://linkedin.com/shareArticle?mini=true&url="+question_path(question, :only_path =>false)+"&title=#{h(question.title)}&summary=#{h(question.body)}&source=Shapado"
      when :think
        url = "http://beta.think.it:3000?"
    end
    url
  end
end
