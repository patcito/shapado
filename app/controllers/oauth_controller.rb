class OauthController < ApplicationController
  def start
    if !current_group.share.fb_active &&
        request.host !~ Regexp.new("#{AppConfig.domain}$", Regexp::IGNORECASE)
      flash[:error] = "facebook integration is not enabled"
      redirect new_session_path(:user)
      return
    end

    if logged_in? && params[:merge]
      merge_token = cookies[:merge_token] = ActiveSupport::SecureRandom.hex(12)
      current_user.set({:merge_token => merge_token})
    end

    # see http://developers.facebook.com/docs/authentication/permissions and
    # http://developers.facebook.com/docs/authentication/
    redirect_to client.web_server.authorize_url(
      :redirect_uri => oauth_callback_url,
      :scope=>'offline_access,publish_stream,email'
    )
  end

  def callback
    access_token = nil
    begin
      access_token = client.web_server.get_access_token(
        params[:code], :redirect_uri => oauth_callback_url
      )
    rescue OAuth2::HTTPError
    end

    if access_token.nil?
      flash[:notice] = "Cannot authenticate you"
      redirect_to root_path
      return
    end

    user_json = access_token.get('/me')
    # in reality you would at this point store the access_token.token value as well as
    # any user info you wanted

    user_json = JSON.parse(user_json)
    atts = {:facebook_id => user_json["id"],
            :facebook_profile => user_json["link"]}

    @user = User.first(:facebook_id => user_json["id"])
    if @user.nil?
      if logged_in? && (token = cookies.delete("merge_token"))
        @user = User.first(:merge_token => token)

        @user.set(atts)
        @user.facebook_id = user_json["id"]
        @user.facebook_profile = user_json["link"]
      else
        @user = User.first(:email => user_json["email"])
      end

      if @user.nil?
        atts[:birthday] = Time.zone.parse(user_json["birthday"]) if user_json["birthday"]
        @user = User.create(atts.merge(
                              :website => user_json["link"],
                              :name => "#{user_json["first_name"]} #{user_json["last_name"]}",
                              :login => user_json["name"],
                              :email => user_json["email"]
                            ))

        if @user.errors.on(:login)
          @user.login = "#{@user.login}_fb"
          @user.save
        end
      elsif @user.facebook_id.nil?
        @user.set(atts)
        @user.facebook_id = user_json["id"]
        @user.facebook_profile = user_json["link"]
      end
    end

    warden.set_user(@user, :scope => "user")
    @user.remember_me!
    after_authentication(@user)

    sign_in_and_redirect(:user, @user, true)
  end

  protected

  def client
    app_id = AppConfig.facebook["key"]
    secret = AppConfig.facebook["secret"]
    if current_group.share.fb_active
      app_id = current_group.share.fb_app_id
      secret = current_group.share.fb_secret_key
    end

    @client ||= OAuth2::Client.new(
      app_id, secret, :site => 'https://graph.facebook.com'
    )
  end
end
