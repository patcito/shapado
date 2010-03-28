module AuthenticatedSystem
  def self.included(controller)
    controller.class_eval do
      alias_method :logged_in?, :user_signed_in?
      helper_method :logged_in?
    end
  end

  protected
  # Attempts to authenticate the given scope by running authentication hooks,
  # but does not redirect in case of failures. Overrode from devise.
  def authenticate(scope)
    warden.authenticate(:scope => scope)
  end

  # Attempts to authenticate the given scope by running authentication hooks,
  # redirecting in case of failures. Overrode from devise.
  def authenticate!(scope)
    warden.authenticate!(:scope => scope)
  end
end
