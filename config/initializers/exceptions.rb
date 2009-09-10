
ExceptionNotifier.configure_exception_notifier do |config|
  config[:exception_recipients] = AppConfig.exception_recipients
  config[:view_path] =  'app/views/error'
end
