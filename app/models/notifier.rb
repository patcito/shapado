class Notifier < ActionMailer::Base
  layout 'notification'
  def new_answer(user, answer)
    recipients user.email
    from "Shapado <notifications@shapado.com>"
    subject "new answer"
    sent_on Time.now
    body   :user => user, :answer => answer, :question => answer.question
  end

end
