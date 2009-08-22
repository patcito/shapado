# This controller handles the login/logout function of the site.
class SessionsController < ApplicationController
  include OpenIdAuthentication

  # render new.rhtml
  def new
  end

  def create
    logout_keeping_session!
    if using_open_id?
      open_id_authentication(params[:openid_identifier])
    else
      password_authentication(params[:login], params[:password])
    end
  end

  def destroy
    logout_killing_session!
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end

protected
  # Track failed login attempts
  def note_failed_signin(message = nil)
    message ||= "Couldn't log you in as '#{params[:login]}'"
    flash[:error] = message
  end

  def password_authentication(login, password)
    user = User.authenticate(login, password)
    if user
      self.current_user = user
      successful_login
    else
      note_failed_signin
      @login       = params[:login]
      @remember_me = true
      render :action => 'new'
    end
  end

  def open_id_authentication(identity_url)
    failed = true
    error_message = nil
    authenticate_with_open_id(
      identity_url,
      :required => [:nickname,
                    :email,
                    'http://axschema.org/contact/email' ]
    ) do |result, identity_url, registration|
      failed = !result.successful?
      if !failed
        if @user = User.find_by_identity_url(identity_url)
          self.current_user = @user
          successful_login
        elsif (@user = create_openid_user(registration, identity_url)) && @user.valid?
          self.current_user = @user
          successful_login(true)
        else
          failed = true
          error_message = result.message
        end
      end

      if failed
        if error_message.blank? && @user
          error_message = @user.errors.full_messages.join(", ")
        end
        note_failed_signin error_message
        redirect_to new_session_path
      end
    end
  end

  def create_openid_user(registration, identity_url)
    google_id = false
    if identity_url =~ %r{//www.google.com}
      google_id = true
      registration["email"] = registration["http://axschema.org/contact/email"][0]
      registration["nickname"] = registration["email"].split(/@/)[0]
    end

    @user = User.find_by_login(registration["nickname"])
    if registration["nickname"].blank? || @user
      if google_id
        login = registration["nickname"]+"_google_id"
      else
        o =  [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten
        string  =  (0..50).map{ o[rand(o.length)]  }.join
        login = URI::parse(identity_url).host.gsub('.','')+URI::parse(identity_url).
        path.gsub('.','').gsub('/','')
      end
    else
      login = registration["nickname"]
    end

    email = registration["email"]

    @user = User.create(:login => login, :email => email, :identity_url=> identity_url)
    if !@user.valid?
      Rails.logger.error("FAILED OPENID LOGIN WITH: #{identity_url} #{registration.inspect}")
      Rails.logger.error(">>>> #{@user.errors.full_messages.join(", ")}")
    end

    @user
  end

  def successful_login(new_user = false)
    new_cookie_flag = (params[:remember_me] == "1")
    handle_remember_cookie! new_cookie_flag

    if new_user
      redirect_back_or_default(edit_user_path(self.current_user))
    else
      redirect_back_or_default('/')
    end
    flash[:notice] = "Logged in successfully"
  end
end
