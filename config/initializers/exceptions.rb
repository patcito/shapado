if AppConfig.exception_notification['activate']
  ExceptionNotifier.configure_exception_notifier do |config|
    config[:exception_recipients] = AppConfig.exception_notification['exception_recipients']
    if !AppConfig.exception_notification['exception_sender_address'].blank?
      config[:sender_address] = AppConfig.exception_notification['exception_sender_address']
    end
    config[:view_path]  = 'app/views/error'
  end
end
