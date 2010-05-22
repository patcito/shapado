class TwitterController < ApplicationController
  def start
    if logged_in? && params[:merge]
      merge_token = cookies[:merge_token] = ActiveSupport::SecureRandom.hex(12)
      current_user.set({:merge_token => merge_token})
    end

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

      atts = {:twitter_token => @access_token.token, :twitter_secret => @access_token.secret}
      @user = User.first(atts)

      if @user.nil?
        if logged_in? && (token = cookies.delete("merge_token"))
          @user = User.first(:merge_token => token)

          if @user
            atts.merge!(:twitter_login => user_json["screen_name"])
            @user.set(atts)
            @user.twitter_token = atts[:twitter_token]
            @user.twitter_secret = atts[:twitter_secret]
            @user.twitter_login = atts[:twitter_login]
          end
        end

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

      else
        @user.set({:twitter_login => user_json["screen_name"]})
      end

      warden.set_user(@user, :scope => "user")
      @user.remember_me!
      after_authentication(@user)

      sign_in_and_redirect(:user, @user, true)
    else
      redirect_to new_session_path(:user)
    end
  end

  def share
    @question = current_group.questions.by_slug(params[:question_id], :select => [:title, :slug])
    url = question_url(@question)
    text = "#{current_group.share.starts_with} #{@question.title} - #{url} #{current_group.share.ends_with}"

    Magent.push("actors.judge", :post_to_twitter, current_user.id, text)

    respond_to do |format|
      format.html {redirect_to url}
      format.js { render :json => { :ok => true }}
    end
  end

  protected
  def client
    @client ||= if logged_in?
      TwitterOAuth::Client.new(
        :consumer_key => AppConfig.twitter["key"],
        :consumer_secret => AppConfig.twitter["secret"],
        :token => current_user.twitter_token,
        :secret => current_user.twitter_secret
      )
    else
      TwitterOAuth::Client.new(
        :consumer_key => AppConfig.twitter["key"],
        :consumer_secret => AppConfig.twitter["secret"]
      )
    end
  end
end
