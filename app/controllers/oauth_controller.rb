class OauthController < ApplicationController
  def start
    redirect_to client.web_server.authorize_url(
      :redirect_uri => oauth_callback_url
    )
  end

  def callback
    access_token = client.web_server.get_access_token(
      params[:code], :redirect_uri => oauth_callback_url
    )

    user_json = access_token.get('/me')
    # in reality you would at this point store the access_token.token value as well as
    # any user info you wanted

    user_json = JSON.parse(user_json)

    @user = User.first(:facebook_id => user_json["id"])
    if @user.nil?
      @user = User.create(:facebook_id => user_json["id"],
                          :website => user_json["link"],
                          :facebook_profile => user_json["link"],
                          :birthday => Time.zone.parse(user_json["birthday"]),
                          :name => "#{user_json["first_name"]} #{user_json["last_name"]}",
                          :login => user_json["name"],
                          :timezone => ActiveSupport::TimeZone[user_json["timezone"]])
    end

    warden.set_user(@user, :scope => "user")
    @user.remember_me!
    after_authentication(@user)

    sign_in_and_redirect(:user, @user, true)
  end

  protected

  def client
    @client ||= OAuth2::Client.new(
      AppConfig.facebook_key, AppConfig.facebook_secret, :site => 'https://graph.facebook.com'
    )
  end
end
