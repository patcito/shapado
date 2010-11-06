class Notifier < ActionMailer::Base
  helper :application
  layout "notifications"

  def give_advice(user, group, question, following = false)
    domain = group ? group.domain : AppConfig.domain
    template_for user do

      scope = "mailers.notifications.give_advice"

      from from_email(group)
      recipients user.email

      if following
        subject I18n.t("friend_subject", :scope => scope, :question_title => question.title)
      else
        subject I18n.t("subject", :scope => scope, :question_title => question.title)
      end
      sent_on Time.now
      body   :user => user, :question => question,
             :group => group, :domain => domain,
             :following => following
    end
  end

  def new_answer(user, group, answer, following = false)
    template_for user do

      scope = "mailers.notifications.new_answer"
      if user == answer.question.user
        @subject = I18n.t("subject_owner", :scope => scope,
                                           :title => answer.question.title,
                                           :login => answer.user.login)
      elsif following
        @subject = I18n.t("subject_friend", :scope => scope,
                                            :title => answer.question.title,
                                            :login => answer.user.login)
      else
        @subject = I18n.t("subject_other", :scope => scope,
                                           :title => answer.question.title,
                                           :login => answer.user.login)
      end

      recipients user.email
      domain = group ? group.domain : AppConfig.domain
      from from_email(group)
      subject @subject
      sent_on Time.now
      body   :user => user, :answer => answer, :question => answer.question,
             :group => group, :domain => domain

    end
  end

  def new_comment(group, comment, user, question)
    domain = group ? group.domain : AppConfig.domain
    recipients user.email
    template_for user do
      from from_email(group)
      subject I18n.t("mailers.notifications.new_comment.subject", :login => comment.user.login, :group => group.name)
      sent_on Time.now

      body :user => user, :comment => comment, :question => question, :group => group, :domain => domain
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
    domain = group ? group.domain : AppConfig.domain
    recipients followed.email
    template_for followed do
      from from_email(group)
      subject I18n.t("mailers.notifications.follow.subject", :login => user.login, :app => AppConfig.application_name)
      sent_on Time.now
      body :user => user, :followed => followed, :group => group, :domain => domain
    end
  end

  def earned_badge(user, group, badge)
    domain = group ? group.domain : AppConfig.domain
    recipients user.email
    template_for user do

      from from_email(group)
      subject I18n.t("mailers.notifications.earned_badge.subject", :group => group.name)
      sent_on Time.now
      body :user => user, :group => group, :badge => badge, :domain => domain
    end
  end

  def favorited(user, group, question)
    domain = group ? group.domain : AppConfig.domain
    recipients question.user.email
    template_for question.user do

      from from_email(group)
      subject I18n.t("mailers.notifications.favorited.subject", :login => user.login)
      sent_on Time.now
      body :user => user, :group => group, :question => question, :domain => domain
    end
  end

  def report(user, report)
    domain = group ? group.domain : AppConfig.domain
    recipients user.email
    template_for user do
      from from_email(group)
      subject I18n.t("mailers.notifications.report.subject", :group => report.group.name, :app => AppConfig.application_name)
      sent_on Time.now

      content_type    "text/plain"
      body :user => user, :report => report, :domain => domain
    end
  end

  private
  def initialize_defaults(method_name)
    super
    @method_name = method_name
  end

  def from_email(group)
    "#{group ? group.name : AppConfig.application_name} <notifications@#{ActionMailer::Base.default_url_options[:host]}>"
  end

  def template_for(user=nil, &block)
    old_lang = I18n.locale
    language = old_lang

    if user && user.language
      language = user.language
    end
    I18n.locale = language

    template_name = "#{@method_name}"
    if Dir.glob(RAILS_ROOT+"/app/views/notifier/#{template_name}*").size == 0
      template_name = @method_name
    end

    @template = template_name

    yield if block
    I18n.locale = old_lang
  end
end
