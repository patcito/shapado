class UsersController < ApplicationController
  before_filter :login_required, :only => [:edit, :update]
  tabs :default => :users
  def index
    @users = User.paginate(:per_page => params[:per_page]||25, :page => params[:page] || 1)
  end

  # render new.rhtml
  def new
    @user = User.new
  end

  def create
    logout_keeping_session!
    @user = User.new(params[:user])
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
    @questions = @user.questions.paginate(:page=>params[:questions_page], :per_page => 10)
    @answers = @user.answers.paginate(:page=>params[:answers_page], :per_page => 10)
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

    if @user.update_attributes(params[:user])
      redirect_to "/settings"
    else
      render :action => "edit"
    end
  end
end
