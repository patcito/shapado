module Notifiable
  def notifiable(&block)
    yield
  rescue => exception
    ExceptionNotifier.deliver_exception_notification(exception)
    raise
  end
end