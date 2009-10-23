class UsersController < ApplicationController
  before_filter :login_required, :only => [:edit, :update]
  tabs :default => :users
  def index
    set_page_title(t("views.users.index.title"))
    @users = User.paginate(:per_page => params[:per_page]||24,
                           :order => "reputation desc",
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
      flash[:notice] = t("flash_notice", :scope => "views.users.create")
    else
      flash[:error]  = t("flash_error", :scope => "views.users.create")
      render :action => 'new'
    end
  end

  def show
    @user = User.find_by_login_or_id(params[:id])
    raise SuperExceptionNotifier::CustomExceptionClasses::PageNotFound unless @user
    @questions = @user.questions.paginate(:page=>params[:questions_page],
                                          :per_page => 10,
                                          :conditions => {:group_id => current_group.id})
    @answers = @user.answers.paginate(:page=>params[:answers_page],
                                      :conditions => {:parent_id => nil,
                                                      :group_id => current_group.id},
                                      :per_page => 10)

    add_feeds_url(url_for(:format => "atom"), t("views.feeds.user"))
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
                         preferred_tags notification_opts], params[:user])
    if @user.valid? && @user.save
      redirect_to root_path
    else
      render :action => "edit"
    end
  end
end
