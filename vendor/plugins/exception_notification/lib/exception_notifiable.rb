require 'ipaddr'

module ExceptionNotifiable
  include SuperExceptionNotifier::CustomExceptionClasses
  include SuperExceptionNotifier::CustomExceptionMethods
  include HooksNotifier

  unless defined?(SILENT_EXCEPTIONS)
    noiseless = []
    noiseless << ActiveRecord::RecordNotFound if defined?(ActiveRecord)
    if defined?(ActionController)
      noiseless << ActionController::UnknownController
      noiseless << ActionController::UnknownAction
      noiseless << ActionController::RoutingError
      noiseless << ActionController::MethodNotAllowed
    end
    SILENT_EXCEPTIONS = noiseless
  end

  # TODO: use ActionController::StatusCodes
  HTTP_ERROR_CODES = { 
    "400" => "Bad Request",
    "403" => "Forbidden",
    "404" => "Not Found",
    "405" => "Method Not Allowed",
    "410" => "Gone",
    "418" => "IÕm a teapot",
    "422" => "Unprocessable Entity",
    "423" => "Locked",
    "500" => "Internal Server Error",
    "501" => "Not Implemented",
    "503" => "Service Unavailable"
  } unless defined?(HTTP_ERROR_CODES)
  
  def self.codes_for_rails_error_classes
    classes = {
      # These are standard errors in rails / ruby
      NameError => "503",
      TypeError => "503",
      RuntimeError => "500",
      ArgumentError => "500",
      # These are custom error names defined in lib/super_exception_notifier/custom_exception_classes
      AccessDenied => "403",
      PageNotFound => "404",
      InvalidMethod => "405",
      ResourceGone => "410",
      CorruptData => "422",
      NoMethodError => "500",
      NotImplemented => "501",
      MethodDisabled => "200"
    }
    # Highly dependent on the verison of rails, so we're very protective about these'
    classes.merge!({ ActionView::TemplateError => "500"})             if defined?(ActionView)       && ActionView.const_defined?(:TemplateError)
    classes.merge!({ ActiveRecord::RecordNotFound => "400" })         if defined?(ActiveRecord)     && ActiveRecord.const_defined?(:RecordNotFound)
    classes.merge!({ ActiveResource::ResourceNotFound => "404" })     if defined?(ActiveResource)   && ActiveResource.const_defined?(:ResourceNotFound)

    if defined?(ActionController)
      classes.merge!({ ActionController::UnknownController => "404" })          if ActionController.const_defined?(:UnknownController)
      classes.merge!({ ActionController::MissingTemplate => "404" })            if ActionController.const_defined?(:MissingTemplate)
      classes.merge!({ ActionController::MethodNotAllowed => "405" })           if ActionController.const_defined?(:MethodNotAllowed)
      classes.merge!({ ActionController::UnknownAction => "501" })              if ActionController.const_defined?(:UnknownAction)
      classes.merge!({ ActionController::RoutingError => "404" })               if ActionController.const_defined?(:RoutingError)
      classes.merge!({ ActionController::InvalidAuthenticityToken => "405" })   if ActionController.const_defined?(:InvalidAuthenticityToken)
    end
  end
  
  def self.included(base)
    base.extend ClassMethods

    # Adds the following class attributes to the classes that include ExceptionNotifiable
    #  HTTP status codes and what their 'English' status message is
    base.cattr_accessor :http_error_codes
    base.http_error_codes = HTTP_ERROR_CODES
    # error_layout:
    #   can be defined at controller level to the name of the desired error layout,
    #   or set to true to render the controller's own default layout,
    #   or set to false to render errors with no layout
    base.cattr_accessor :error_layout
    base.error_layout = nil
    # Rails error classes to rescue and how to rescue them (which error code to use)
    base.cattr_accessor :rails_error_classes
    base.rails_error_classes = self.codes_for_rails_error_classes
    # Verbosity of the gem
    base.cattr_accessor :exception_notifier_verbose
    base.exception_notifier_verbose = false
    # Do Not Ever send error notification emails for these Error Classes
    base.cattr_accessor :silent_exceptions
    base.silent_exceptions = SILENT_EXCEPTIONS
    # Notification Level
    base.cattr_accessor :notification_level
    base.notification_level = [:render, :email, :web_hooks]
  end
  
  module ClassMethods
    # specifies ip addresses that should be handled as though local
    def consider_local(*args)
      local_addresses.concat(args.flatten.map { |a| IPAddr.new(a) })
    end

    def local_addresses
      addresses = read_inheritable_attribute(:local_addresses)
      unless addresses
        addresses = [IPAddr.new("127.0.0.1")]
        write_inheritable_attribute(:local_addresses, addresses)
      end
      addresses
    end

    # set the exception_data deliverer OR retrieve the exception_data
    def exception_data(deliverer = nil)
      if deliverer
        write_inheritable_attribute(:exception_data, deliverer)
      else
        read_inheritable_attribute(:exception_data)
      end
    end
  end

  private

    def notification_level_renders?
      self.class.notification_level.include?(:render)
    end
    def notification_level_sends_email?
      self.class.notification_level.include?(:email)
    end
    def notification_level_sends_web_hooks?
      self.class.notification_level.include?(:web_hooks)
    end

    # overrides Rails' local_request? method to also check any ip
    # addresses specified through consider_local.
    def local_request?
      remote = IPAddr.new(request.remote_ip)
      !self.class.local_addresses.detect { |addr| addr.include?(remote) }.nil?
    end

    # When the action being executed has its own local error handling (rescue)
    def rescue_with_handler(exception)
      to_return = super
      if to_return
        data = get_exception_data
        status_code = status_code_for_exception(exception)
        #We only send email if it has been configured in environment
        send_email = should_email_on_exception?(exception, status_code, self.class.exception_notifier_verbose)
        #We only send web hooks if they've been configured in environment
        send_web_hooks = should_web_hook_on_exception?(exception, status_code, self.class.exception_notifier_verbose)
        the_blamed = ExceptionNotifier.config[:git_repo_path].nil? ? nil : lay_blame(exception)
        verbose_output(exception, status_code, "rescued by handler", send_email, send_web_hooks, nil, the_blamed) if self.class.exception_notifier_verbose
        # Send the exception notificaiton email
        perform_exception_notify_mailing(exception, data, nil, the_blamed) if send_email
        # Send Web Hook requests
        HooksNotifier.deliver_exception_to_web_hooks(ExceptionNotifier.config, exception, self, request, data, the_blamed) if send_web_hooks
      end
      to_return
    end

    # When the action being executed is letting SEN handle the exception completely
    def rescue_action_in_public(exception)
      # If the error class is NOT listed in the rails_errror_class hash then we get a generic 500 error:
      # OTW if the error class is listed, but has a blank code or the code is == '200' then we get a custom error layout rendered
      # OTW the error class is listed!
      verbose = self.class.exception_notifier_verbose
      status_code = status_code_for_exception(exception)
      if status_code == '200'
        notify_and_render_error_template(status_code, request, exception, ExceptionNotifier.get_view_path_for_class(exception, verbose), verbose)
      else
        notify_and_render_error_template(status_code, request, exception, ExceptionNotifier.get_view_path_for_status_code(status_code, verbose), verbose)
      end
    end

    def notify_and_render_error_template(status_cd, request, exception, file_path, verbose = false)
      status = self.class.http_error_codes[status_cd] ? status_cd + " " + self.class.http_error_codes[status_cd] : status_cd
      data = get_exception_data
      #We only send email if it has been configured in environment
      send_email = should_email_on_exception?(exception, status_cd, verbose)
      #We only send web hooks if they've been configured in environment
      send_web_hooks = should_web_hook_on_exception?(exception, status_cd, verbose)
      the_blamed = ExceptionNotifier.config[:git_repo_path].nil? ? nil : lay_blame(exception)

      # Debugging output
      verbose_output(exception, status_cd, file_path, send_email, send_web_hooks, request, the_blamed) if verbose
      # Send the email before rendering to avert possible errors on render preventing the email from being sent.
      perform_exception_notify_mailing(exception, data, request, the_blamed) if send_email
      # Send Web Hook requests
      HooksNotifier.deliver_exception_to_web_hooks(ExceptionNotifier.config, exception, self, request, data, the_blamed) if send_web_hooks
      # Render the error page to the end user
      render_error_template(file_path, status)
    end

    def get_exception_data
      deliverer = self.class.exception_data
      return case deliverer
        when nil then {}
        when Symbol then send(deliverer)
        when Proc then deliverer.call(self)
      end
    end

    def render_error_template(file, status)
      respond_to do |type|
        type.html { render :file => file,
                            :layout => self.class.error_layout,
                            :status => status }
        type.all  { render :nothing => true,
                            :status => status}
      end
    end

    def verbose_output(exception, status_cd, file_path, send_email, send_web_hooks, request = nil, the_blamed = nil)
      puts "[EXCEPTION] #{exception}"
      puts "[EXCEPTION CLASS] #{exception.class}"
      puts "[EXCEPTION STATUS_CD] #{status_cd}"
      puts "[ERROR LAYOUT] #{self.class.error_layout}" if self.class.error_layout
      puts "[ERROR VIEW PATH] #{ExceptionNotifier.config[:view_path]}" if !ExceptionNotifier.nil? && !ExceptionNotifier.config[:view_path].nil?
      puts "[ERROR FILE PATH] #{file_path.inspect}"
      puts "[ERROR EMAIL] #{send_email ? "YES" : "NO"}"
      puts "[ERROR WEB HOOKS] #{send_web_hooks ? "YES" : "NO"}"
      puts "[COMPAT MODE] #{ExceptionNotifierHelper::COMPAT_MODE ? "YES" : "NO"}"
      puts "[THE BLAMED] #{the_blamed}"
      req = request ? " for request_uri=#{request.request_uri} and env=#{request.env.inspect}" : ""
      logger.error("render_error(#{status_cd}, #{self.class.http_error_codes[status_cd]}) invoked#{req}") if !logger.nil?
    end

    def perform_exception_notify_mailing(exception, data, request = nil, the_blamed = nil)
      if !ExceptionNotifier.config[:exception_recipients].blank?
        # Send email with ActionMailer
        ExceptionNotifier.deliver_exception_notification(exception, self,
          request, data, the_blamed)
      end
    end

    def should_email_on_exception?(exception, status_cd = nil, verbose = false)
      notification_level_sends_email? && !ExceptionNotifier.config[:exception_recipients].empty? && should_notify_on_exception?(exception, status_cd, verbose)
    end

    def should_web_hook_on_exception?(exception, status_cd = nil, verbose = false)
      notification_level_sends_web_hooks? && !ExceptionNotifier.config[:web_hooks].empty? && should_notify_on_exception?(exception, status_cd, verbose)
    end

    def should_notify_on_exception?(exception, status_cd = nil, verbose = false)
      # don't notify (email or web hooks) on exceptions raised locally
      puts "skipping local notification" if verbose && ExceptionNotifier.config[:skip_local_notification] && is_local?
      return false if ExceptionNotifier.config[:skip_local_notification] && is_local?
      # don't notify (email or web hooks) exceptions raised that match ExceptionNotifiable.silent_exceptions
      return false if self.class.silent_exceptions.respond_to?(:any?) && self.class.silent_exceptions.any? {|klass| klass === exception }
      return true if ExceptionNotifier.config[:notify_error_classes].include?(exception.class)
      return true if !status_cd.nil? && ExceptionNotifier.config[:notify_error_codes].include?(status_cd)
      return ExceptionNotifier.config[:notify_other_errors]
    end

    def is_local?
      (consider_all_requests_local || local_request?)
    end

    def status_code_for_exception(exception)
      self.class.rails_error_classes[exception.class].nil? ? '500' : self.class.rails_error_classes[exception.class].blank? ? '200' : self.class.rails_error_classes[exception.class]
    end

    def lay_blame(exception)
      error = {}
      unless(ExceptionNotifier.config[:git_repo_path].nil?)
        if(exception.class == ActionView::TemplateError)
            blame = blame_output(exception.line_number, "app/views/#{exception.file_name}")
            error[:author] = blame[/^author\s.+$/].gsub(/author\s/,'')
            error[:line]   = exception.line_number
            error[:file]   = exception.file_name
        else
          exception.backtrace.each do |line|
            file = exception_in_project?(line[/^.+?(?=:)/])
            unless(file.nil?)
              line_number = line[/:\d+:/].gsub(/[^\d]/,'')
              # Use relative path or weird stuff happens
              blame = blame_output(line_number, file.gsub(Regexp.new("#{RAILS_ROOT}/"),''))
              error[:author] = blame[/^author\s.+$/].sub(/author\s/,'')
              error[:line]   = line_number
              error[:file]   = file
              break
            end
          end
        end
      end
      error
    end
  
    def blame_output(line_number, path)
      app_directory = Dir.pwd
      Dir.chdir ExceptionNotifier.config[:git_repo_path]
      blame = `git blame -p -L #{line_number},#{line_number} #{path}`
      Dir.chdir app_directory
  
      blame
    end
  
    def exception_in_project?(path) # should be a path like /path/to/broken/thingy.rb
      dir = File.split(path).first rescue ''
      if(File.directory?(dir) and !(path =~ /vendor\/plugins/) and !(path =~ /vendor\/gems/) and path.include?(RAILS_ROOT))
        path
      else
        nil
      end
    end

end
