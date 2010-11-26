class Notifier < ActionMailer::Base
  helper :application
  layout "notifications"

  def give_advice(user, group, question, following = false)
    setup_email(group, user) do
      scope = "mailers.notifications.give_advice"

      if following
        subject I18n.t("friend_subject", :scope => scope, :question_title => question.title, :locale => @language)
      else
        subject I18n.t("subject", :scope => scope, :question_title => question.title, :locale => @language)
      end

      body   :user => user, :question => question,
      :group => group, :domain => domain_for(group),
      :following => following
    end
  end

  def new_answer(user, group, answer, following = false)
    setup_email(group, user) do
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

      subject @subject
      body   :user => user, :answer => answer, :question => answer.question,
      :group => group, :domain => domain_for(group)
    end
  end

  def new_comment(group, comment, user, question)
    setup_email(group, user) do
      subject I18n.t("mailers.notifications.new_comment.subject", :login => comment.user.login, :group => group.name, :locale => @language)
      body :user => user, :comment => comment, :question => question, :group => group, :domain => domain_for(group)
    end
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
    setup_email(group, followed) do
      subject I18n.t("mailers.notifications.follow.subject", :login => user.login, :app => AppConfig.application_name, :locale => @language)
      body :user => user, :followed => followed, :group => group, :domain => domain_for(group)
    end
  end

  def earned_badge(user, group, badge)
    setup_email(group, user) do
      subject I18n.t("mailers.notifications.earned_badge.subject", :group => group.name, :locale => @language)
      body :user => user, :group => group, :badge => badge, :domain => domain_for(group)
    end
  end

  def favorited(user, group, question)
    setup_email(group, question.user) do
      subject I18n.t("mailers.notifications.favorited.subject", :login => user.login, :locale => @language)
      body :user => user, :group => group, :question => question, :domain => domain_for(group)
    end
  end

  def report(user, report, group)
    setup_email(group, user) do
      subject I18n.t("mailers.notifications.report.subject", :group => report.group.name, :app => AppConfig.application_name, :locale => @language)
      body :user => user, :report => report, :domain => domain_for(group)
    end
  end

  private
  def from_email(group)
    "#{group ? group.name : AppConfig.application_name} <notifications@#{ActionMailer::Base.default_url_options[:host]}>"
  end

  def domain_for(group)
    group ? group.domain : AppConfig.domain
  end

  def setup_email(group, user, &block)
    @language = language_for(user)
    set_locale @language

    recipients user.email
    from from_email(group)
    sent_on Time.now

    ret = block.call

    ret
  end

  def language_for(user=nil)
    if user && user.language
     user.language
   else
     I18n.locale
   end
  end
end
