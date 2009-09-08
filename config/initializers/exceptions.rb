
ExceptionNotifier.configure_exception_notifier do |config|
  config[:exception_recipients] = AppConfig.exception_recipients
end
