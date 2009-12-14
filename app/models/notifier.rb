class Notifier < ActionMailer::Base

  def new_answer(user, group, answer)
    self.class.layout "notification_#{user.language.downcase}"

    I18n.locale = user.language
    scope = "mailers.notifications.new_answer"
    if user == answer.question.user
      @subject = I18n.t("subject_owner", :scope => scope,
                                         :title => answer.question.title,
                                         :login => answer.user.login)
    else
      @subject = I18n.t("subject_other", :scope => scope,
                                         :title => answer.question.title,
                                         :login => answer.user.login)
    end

    recipients user.email
    domain = group ? group.domain : AppConfig.domain
    from "#{group ? group.name : AppConfig.application_name} <notifications@shapado.com>"
    subject @subject
    sent_on Time.now
    body   :user => user, :answer => answer, :question => answer.question,
           :group => group, :domain => domain
    template "new_answer_#{user.language.downcase}"
    content_type  "text/html"
  end

  def new_feedback(user, subject, content)
    recipients AppConfig.exception_recipients
    from "Shapado[feedback] <notifications@shapado.com>"
    subject "feedback: #{subject}"
    sent_on Time.now
    body   :user => user, :subject => subject, :content => content
    content_type  "text/plain"
  end

  protected
end
