class Notifier < ActionMailer::Base


  def new_answer(user, answer)
    self.class.layout "notification_#{user.language.downcase}"

    if user == answer.question.user
      @subject = "#{answer.user.login} answered your question #{answer.question.title}"
    else
      @subject = "#{answer.user.login} answered the question #{answer.question.title}"
    end

    recipients user.email
    from "Shapado <notifications@shapado.com>"
    subject @subject
    sent_on Time.now
    body   :user => user, :answer => answer, :question => answer.question
    template "new_answer_#{user.language.downcase}"
    content_type  "text/html"
  end

  protected
end
