class UsersController < ApplicationController
  before_filter :login_required, :only => [:edit, :update, :follow]
  tabs :default => :users
  def index
    set_page_title(t("users.index.title"))
    @users = User.paginate(:per_page => params[:per_page]||24,
                          :order => "reputation.#{current_group.id} desc",
                          :conditions => {:"reputation.#{current_group.id}" => {:"$exists" => true}},
                          :page => params[:page] || 1)

    respond_to do |format|
      format.html
    end

  end

  # render new.rhtml
  def new
    @user = User.new
  end

  def create
    logout_keeping_session!
    @user = User.new
    @user.safe_update(%w[login email name password_confirmation password
                         language timezone identity_url bio], params[:user])
    success = @user && @user.save
    if success && @user.errors.empty?
      # Protects against session fixation attacks, causes request forgery
      # protection if visitor resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset session
      self.current_user = @user # !! now logged in
      current_user.localize(request.remote_ip)
      redirect_back_or_default('/')
      flash[:notice] = t("flash_notice", :scope => "users.create")
    else
      flash[:error]  = t("flash_error", :scope => "users.create")
      render :action => 'new'
    end
  end

  def show
    @user = User.find_by_login_or_id(params[:id])
    raise PageNotFound unless @user
    @questions = @user.questions.paginate(:page=>params[:questions_page],
                                          :per_page => 10,
                                          :group_id => current_group.id,
                                          :banned => false)
    @answers = @user.answers.paginate(:page=>params[:answers_page],
                                      :group_id => current_group.id,
                                      :per_page => 10,
                                      :banned => false)

    @badges = @user.badges.paginate(:page => params[:badges_page],
                                    :group_id => current_group.id,
                                    :per_page => 25)

    @favorites = @user.favorites.paginate(:page => params[:favorites_page],
                                          :per_page => 25,
                                          :group_id => current_group.id)

    @favorite_questions = Question.find(@favorites.map{|f| f.question_id })

    add_feeds_url(url_for(:format => "atom"), t("feeds.user"))

    @user.stats.viewed! if @user != current_user && !is_bot?
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if params[:current_password] && User.authenticate(@user.login, params[:current_password])
      @user.crypted_password = ""
      @user.password = params[:user][:password]
      @user.password_confirmation = params[:user][:password_confirmation]
    end

    @user.safe_update(%w[login email name password_confirmation password
                         language timezone preferred_languages
                         notification_opts bio], params[:user])
    preferred_tags = params[:user][:preferred_tags]
    if @user.valid? && @user.save
      @user.set_preferred_tags(preferred_tags, current_group) if preferred_tags
      redirect_to root_path
    else
      render :action => "edit"
    end
  end

  def change_preferred_tags
    @user = current_user
    if params[:tags]
      if params[:opt] == "add"
        @user.add_preferred_tags(params[:tags], current_group) if params[:tags]
      elsif params[:opt] == "remove"
        @user.remove_preferred_tags(params[:tags], current_group)
      end
    end

    respond_to do |format|
      format.html {redirect_to questions_path(current_languages)}
    end
  end

  def follow
    @user = User.find_by_login_or_id(params[:id])
    current_user.add_friend(@user)

    flash[:notice] = t("flash_notice", :scope => "users.follow", :user => @user.login)

    if @user.notification_opts.activities
      Notifier.deliver_follow(current_user, @user)
    end

    Magent.push("actors.judge", :on_follow, current_user.id, @user.id, current_group.id)

    respond_to do |format|
      format.html do
        redirect_to user_path(@user)
      end
    end
  end

  def unfollow
    @user = User.find_by_login_or_id(params[:id])
    current_user.remove_friend(@user)

    flash[:notice] = t("flash_notice", :scope => "users.unfollow", :user => @user.login)

    Magent.push("actors.judge", :on_unfollow, current_user.id, @user.id, current_group.id)

    respond_to do |format|
      format.html do
        redirect_to user_path(@user)
      end
    end
  end

  def autocomplete_for_user_login
    @users = User.all( :limit => params[:limit] || 20,
                       :fields=> 'login',
                       :login =>  /^#{params[:prefix].downcase.to_s}.*/,
                       :order => "login desc")
    respond_to do |format|
      format.json {render :json=>@users}
    end
  end
end


