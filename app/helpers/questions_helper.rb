module QuestionsHelper
  def microblogging_message(question)
    message = "#{h(question.title)}"
    message += " "
    message +=  escape_url(question_path(question, :only_path =>false))
    message
  end

  def linkedin_url(question)
    linkedin_share = question_path(question, :only_path =>false)
  end

  def share_url(question, service)
    url = ""
    case service
      when :twitter
        if logged_in? && current_user.twitter_token.present?
          url = twitter_share_url(:question_id => question.id)
        else
          url = "http://twitter.com/?status=#{microblogging_message(question)}"
        end
      when :identica
        url = "http://identi.ca/notice/new?status_textarea=#{microblogging_message(question)}" 
      when :shapado
        #SP: The rationale here is that when in a group site, you can share a question with the main site, however if you are on the main site then this share is hidden (no point in referring to iteself after all)
        url = "http://shapado.com/questions/new?question[title]="+(question.title)+"&question[tags]=#{current_group.name},share&question[body]=#{h(question.body)}%20|%20[More...](#{h(question_path(question, :only_path =>false))})"
      when :facebook
        if current_group.fb_button
          url = %@<iframe src="http://www.facebook.com/plugins/like.php?href=#{escape_url(question_path(question, :only_path =>false))}&amp;layout=button_count&amp;show_faces=true&amp;width=450&amp;action=like&amp;font&amp;colorscheme=light&amp;height=21" scrolling="no" frameborder="0" style="border:none; overflow:hidden; width:450px; height:21px;" allowTransparency="true"></iframe>@
        else
          fb_url = "http://www.facebook.com/sharer.php?u=#{escape_url(question_path(question, :only_path =>false))}&t=#{question.title}"
          url = %@#{image_tag('/images/hi16-app-facebook_microblog.png', :class => 'microblogging')} #{link_to("facebook", fb_url, :rel=>"nofollow external")}@
        end
      when :linkedin
        url = "http://linkedin.com/shareArticle?mini=true&url="+URL.escape(question_url(question))+"&title=#{h(question.title)}&summary=#{h(question.body)}&source=#{current_group.name}"
      when :think
        url = "http://thnik.it/thoughts/new?question[title]="+(question.title)+"&question[tags]=#{current_group.name},share&question[body]=#{h(question.body)}%20|%20[More...](#{h(question_path(question, :only_path =>false))})"
    end
    url
  end

  protected
  def escape_url(url)
    URI.escape(url, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end
end
