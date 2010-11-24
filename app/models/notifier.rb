class Notifier < ActionMailer::Base
  helper :application
  layout "notifications"

  def give_advice(user, group, question, following = false)
    domain = group ? group.domain : AppConfig.domain
    @language = language_for(user)
    set_locale @language
    scope = "mailers.notifications.give_advice"

    from from_email(group)
    recipients user.email

    if following
      subject I18n.t("friend_subject", :scope => scope, :question_title => question.title, :locale => @language)
    else
      subject I18n.t("subject", :scope => scope, :question_title => question.title, :locale => @language)
    end
    sent_on Time.now
    body   :user => user, :question => question,
    :group => group, :domain => domain,
    :following => following
  end

  def new_answer(user, group, answer, following = false)
    @language = language_for(user)
    set_locale @language

    scope = "mailers.notifications.new_answer"
    if user == answer.question.user
      @subject = I18n.t("subject_owner", :scope => scope,
                        :title => answer.question.title,
                        :login => answer.user.login, :locale => @language)
    elsif following
      @subject = I18n.t("subject_friend", :scope => scope,
                        :title => answer.question.title,
                        :login => answer.user.login, :locale => @language)
    else
      @subject = I18n.t("subject_other", :scope => scope,
                        :title => answer.question.title,
                        :login => answer.user.login, :locale => @language)
    end

    recipients user.email
    domain = group ? group.domain : AppConfig.domain
    from from_email(group)
    subject @subject
    sent_on Time.now
    body   :user => user, :answer => answer, :question => answer.question,
    :group => group, :domain => domain

  end

  def new_comment(group, comment, user, question)
    domain = group ? group.domain : AppConfig.domain
    recipients user.email
    @language = language_for(user)
    set_locale @language

    from from_email(group)
    subject I18n.t("mailers.notifications.new_comment.subject", :login => comment.user.login, :group => group.name, :locale => @language)
    sent_on Time.now

    body :user => user, :comment => comment, :question => question, :group => group, :domain => domain
  end

  def new_feedback(user, subject, content, email, ip)
    #self.class.layout ""
    recipients AppConfig.exception_notification["exception_recipients"]
    from "Shapado[feedback] <#{AppConfig.notification_email}>"
    subject "feedback: #{subject}"
    sent_on Time.now
    body   :user => user, :subject => subject, :content => content, :email => email, :ip => ip
    content_type  "text/plain"
  end

  def follow(group, user, followed)
    domain = group ? group.domain : AppConfig.domain
    recipients followed.email
    @language = language_for(followed)
    set_locale @language

    from from_email(group)
    subject I18n.t("mailers.notifications.follow.subject", :login => user.login, :app => AppConfig.application_name, :locale => @language)
    sent_on Time.now
    body :user => user, :followed => followed, :group => group, :domain => domain
  end

  def earned_badge(user, group, badge)
    domain = group ? group.domain : AppConfig.domain
    recipients user.email
    @language = language_for(user)
    set_locale @language

    from from_email(group)
    subject I18n.t("mailers.notifications.earned_badge.subject", :group => group.name, :locale => @language)
    sent_on Time.now
    body :user => user, :group => group, :badge => badge, :domain => domain
  end

  def favorited(user, group, question)
    domain = group ? group.domain : AppConfig.domain
    recipients question.user.email
    @language = language_for(question.user)
    set_locale @language

    from from_email(group)
    subject I18n.t("mailers.notifications.favorited.subject", :login => user.login, :locale => @language)
    sent_on Time.now
    body :user => user, :group => group, :question => question, :domain => domain
  end

  def report(user, report, group)
    domain = group ? group.domain : AppConfig.domain
    recipients user.email
    @language = language_for(user)
    set_locale @language

    from from_email(group)
    subject I18n.t("mailers.notifications.report.subject", :group => report.group.name, :app => AppConfig.application_name, :locale => @language)
    sent_on Time.now
    content_type    "text/plain"
    body :user => user, :report => report, :domain => domain
  end

  private
  def from_email(group)
    "#{group ? group.name : AppConfig.application_name} <notifications@#{ActionMailer::Base.default_url_options[:host]}>"
  end

  def language_for(user=nil)
    @language = if user && user.language
                 @language = user.language
               else
                 I18n.locale
               end
  end
end
