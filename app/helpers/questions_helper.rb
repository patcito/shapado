module QuestionsHelper
  def microblogging_message(question)
    message = "#{h(question.title)}"
    message += " "
    message +=  question_path(question, :only_path =>false)
    message
  end

  def linkedin_url(question)
    linkedin_share = question_path(question, :only_path =>false)
  end

  def share_url(question, service)
    url = ""
    case service
      when :identica
        url = "http://identi.ca/notice/new?status_textarea=#{microblogging_message(question)}"

#SP: The rationale here is that when in a group site, you can share a question with the main site, however if you are on the main site then this share is hidden (no point in referring to iteself after all)
    
      when :shapado
#      ~-if !current_group
        url = "http://shapado.com/questions/new?question[title]="+(question.title)+"&question[tags]=#{current_group.name},share&question[body]=#{h(question.body)}%20|%20[More...](#{h(question_path(question, :only_path =>false))})"


      when :twitter
        url = "http://twitter.com/?status=#{microblogging_message(question)}"
      when :facebook
        url = "http://www.facebook.com/sharer.php?u=#{question_path(question, :only_path =>false)}&t=#{h(question.title)}"

#SP: The LinkedIn url needs to be url encoded but I can't quite seem to figure it out, the http:// needs to be http%3A//

      when :linkedin
        #require "cgi"
        url = "http://linkedin.com/shareArticle?mini=true&url="+CGI.escape(question_url(question))+"&title=#{h(question.title)}&summary=#{h(question.body)}&source=#{current_group.name}"

      when :think
        url = "http://thnik.it/thoughts/new?question[title]="+(question.title)+"&question[tags]=#{current_group.name},share&question[body]=#{h(question.body)}%20|%20[More...](#{h(question_path(question, :only_path =>false))})"
    end
    url
  end
end
