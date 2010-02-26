class Notifier < ActionMailer::Base
  def give_advice(user, group, question)
    I18n.locale = user.language
    scope = "mailers.notifications.give_advice"

    from "#{group ? group.name : AppConfig.application_name} <#{AppConfig.notification_email}>"
    recipients user.email
    subject I18n.t("subject", :scope => scope, :question_title => question.title) # FIXME
    sent_on Time.now
    body   :user => user, :question => question,
           :group => group, :domain => group.domain
  end

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
    from "#{group ? group.name : AppConfig.application_name} <#{AppConfig.notification_email}>"
    subject @subject
    sent_on Time.now
    body   :user => user, :answer => answer, :question => answer.question,
           :group => group, :domain => domain
    template "new_answer_#{user.language.downcase}"
    content_type  "text/html"
  end

  def new_feedback(user, subject, content, email, ip)
    recipients AppConfig.exception_recipients
    from "Shapado[feedback] <#{AppConfig.notification_email}>"
    subject "feedback: #{subject}"
    sent_on Time.now
    body   :user => user, :subject => subject, :content => content, :email => email, :ip => ip
    content_type  "text/plain"
  end

  def follow(user, followed)
    recipients followed.email
    from "Shapado <#{AppConfig.notification_email}>"
    subject "#{user.login} is now following you on #{AppConfig.application_name}"
    sent_on Time.now
    body :user => user, :followed => followed
  end

  def earned_badge(user, group, badge)
    recipients user.email
    from "Shapado <#{AppConfig.notification_email}>"
    subject "You have earned a badge on #{group.name}!"
    sent_on Time.now
    body :user => user, :group => group, :badge => badge
    content_type    "multipart/alternative"
  end

  protected
end
