class Notifier < ActionMailer::Base
  helper :application

  def give_advice(user, group, question)
    template_for user

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
    template_for user

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

    content_type  "text/html"
  end

  def new_comment(group, comment, user, question)
    recipients user.email
    template_for user
    from "Shapado <#{AppConfig.notification_email}>"
    subject I18n.t("mailers.notifications.new_comment.subject", :login => user.login, :app => AppConfig.application_name)
    sent_on Time.now
    content_type    "multipart/alternative"

    body :user => user, :comment => comment, :question => question, :group => group
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
    template_for followed
    from "Shapado <#{AppConfig.notification_email}>"
    subject I18n.t("mailers.notifications.follow.subject", :login => user.login, :app => AppConfig.application_name)
    sent_on Time.now
    body :user => user, :followed => followed
  end

  def earned_badge(user, group, badge)
    recipients user.email
    template_for user

    from "Shapado <#{AppConfig.notification_email}>"
    subject I18n.t("mailers.notifications.earned_badge.subject", :group => group.name)
    sent_on Time.now
    body :user => user, :group => group, :badge => badge
    content_type    "multipart/alternative"
  end

  def favorited(user, group, question)
    recipients question.user.email
    template_for question.user

    from "Shapado <#{AppConfig.notification_email}>"
    subject I18n.t("mailers.notifications.favorited.subject", :login => user.login)
    sent_on Time.now
    body :user => user, :group => group, :question => question
    content_type    "multipart/alternative"
  end

  def report(user, report)
    recipients user.email
    template_for user

    from "Shapado <#{AppConfig.notification_email}>"
    subject I18n.t("mailers.notifications.report.subject")
    sent_on Time.now

    body :user => user, :report => report
    content_type    "multipart/alternative"
  end

  private
  def initialize_defaults(method_name)
    super
    @method_name = method_name
  end

  def template_for(user=nil)
    language = I18n.locale

    if user && user.language
      language = user.language
      I18n.locale = user.language
    end

    template_name = "#{@method_name}_#{language}"
    if Dir.glob(RAILS_ROOT+"/app/views/notifier/#{template_name}*").size == 0
      template_name = @method_name
    end

    @template = template_name
  end
end
