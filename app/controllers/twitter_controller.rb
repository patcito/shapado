class TwitterController < ApplicationController
  def start
    request_token = client.request_token(
      :oauth_callback => twitter_callback_url
    )

    cookies["request_token"] = request_token.token
    cookies["request_token_secret"] = request_token.secret

    redirect_to request_token.authorize_url.gsub('authorize', 'authenticate')
  end

  def callback
    request_token = cookies.delete("request_token")
    request_token_create = cookies.delete("request_token_secret")

    begin
      @access_token = client.authorize(
        request_token,
        request_token_create,
        :oauth_verifier => params[:oauth_verifier]
      )
    rescue OAuth::Unauthorized
    end

    if client.authorized?
      user_json = JSON.parse(@access_token.response.body)

      @user = User.first(:twitter_token => @access_token.token, :twitter_secret => @access_token.secret)
      if @user.nil?
        @user = User.create(:twitter_token => @access_token.token,
                            :twitter_secret => @access_token.secret,
                            :login => user_json["screen_name"],
                            :website => user_json["url"],
                            :location => user_json["location"],
                            :name => user_json["name"],
                            :language => find_valid_locale(user_json["lang"]))

        if @user.errors.on(:login)
          @user.login = "#{@user.login}_twitter"
          @user.save
        end
      end

      warden.set_user(@user, :scope => "user")
      @user.remember_me!
      after_authentication(@user)

      sign_in_and_redirect(:user, @user, true)
    else
      redirect_to new_session_path(:user)
    end
  end

  protected
  def client
    @client ||= TwitterOAuth::Client.new(
      :consumer_key => AppConfig.twitter["key"],
      :consumer_secret => AppConfig.twitter["secret"]
    )
  end
end
