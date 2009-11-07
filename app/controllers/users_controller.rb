class UsersController < ApplicationController
  before_filter :login_required, :only => [:edit, :update]
  tabs :default => :users
  def index
    set_page_title(t("users.index.title"))
    @users = User.paginate(:per_page => params[:per_page]||24,
                           :order => "reputation.#{current_group.id} desc",
                           :conditions => {:"reputation.#{current_group.id}" => {:"$exists" => true}},
                           :page => params[:page] || 1)
  end

  # render new.rhtml
  def new
    @user = User.new
  end

  def create
    logout_keeping_session!
    @user = User.new
    @user.safe_update(%w[login email name password_confirmation password
                         language timezone identity_url], params[:user])
    success = @user && @user.save
    if success && @user.errors.empty?
      # Protects against session fixation attacks, causes request forgery
      # protection if visitor resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset session
      self.current_user = @user # !! now logged in
      redirect_back_or_default('/')
      flash[:notice] = t("flash_notice", :scope => "users.create")
    else
      flash[:error]  = t("flash_error", :scope => "create")
      render :action => 'new'
    end
  end

  def show
    @user = User.find_by_login_or_id(params[:id])
    raise SuperExceptionNotifier::CustomExceptionClasses::PageNotFound unless @user
    @questions = @user.questions.paginate(:page=>params[:questions_page],
                                          :per_page => 10,
                                          :group_id => current_group.id)
    @answers = @user.answers.paginate(:page=>params[:answers_page],
                                      :parent_id => nil,
                                      :group_id => current_group.id,
                                      :per_page => 10)

    add_feeds_url(url_for(:format => "atom"), t("feeds.user"))
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
                         language timezone preferred_languages categories
                         notification_opts], params[:user])
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
      format.html {redirect_to questions_path(current_category)}
    end
  end
end


