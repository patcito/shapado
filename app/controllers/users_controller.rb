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
      flash[:notice] = "Thanks for signing up!  We're sending you an email with your activation code."
    else
      flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
      render :action => 'new'
    end
  end

  def show
    @user = User.find_by_login_or_id(params[:id])
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
