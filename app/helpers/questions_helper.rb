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
        url = "http://shapado.com/questions/new?question[title]="+(question.title)+"&question[tags]=#{current_group.name},share&question[body]=#{h(question.body)}%20|%20[More...](#{h(question_path(question, :only_path =>false))})"
      when :twitter
        url = "http://twitter.com/?status=#{microblogging_message(question)}"
      when :facebook
        url = "http://www.facebook.com/sharer.php?u=#{question_path(question, :only_path =>false)}&t=#{h(question.title)}"

#SP: The LinkedIn url needs to be url encoded but I can't quite seem to figure it out

      when :linkedin
        url = "http://linkedin.com/shareArticle?mini=true&url=&title=#{h(question.title)}&summary=#{h(question.body)}&source=#{current_group.name}"
      when :think
        url = "http://beta.think.it:3000/thoughts/new?question[title]="+(question.title)+"&question[tags]=#{current_group.name},share&question[body]=#{h(question.body)}%20|%20[More...](#{h(question_path(question, :only_path =>false))})"
    end
    url
  end
end
