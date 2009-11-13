
class MembersController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  before_filter :check_permissions, :only => [:create, :update, :edit, :destroy]

  def index
    @group = Group.find_by_slug_or_id(params[:group_id])
    @members = @group.memberships.paginate(:page => params[:page] || 1,
                                           :per_page => params[:per_page] || 25)
    @member = Member.new
  end

  def create
    @user = User.find_by_login(params[:member][:user_id])
    if @user
      @member = @group.add_member(@user, params[:member][:role])
      if @member.valid?
        return redirect_to group_members_path(@group)
      end
    else
      flash[:error] = "Sorry, the user **#{params[:member][:user_id]}** does not exists"
      @member = Member.new
    end

    @members = @group.memberships.paginate(:page => params[:page] || 1,
                                       :per_page => params[:per_page] || 25)
    render :index
  end

  def update
    @member = @group.memberships.find(params[:id])
    if @member.user_id != current_user.id || current_user.admin?
      @member.role = params[:member][:role]
      @member.save
    else
      flash[:error] = "Sorry, you cannot be change the **#{@member.user.login}'s** membership"
    end
    redirect_to group_members_path(@group)
  end

  def destroy
    @member = @group.memberships.find(params[:id])
    if (@member.user_id != current_user.id) || current_user.admin?
      @member.destroy
    else
      flash[:error] = "Sorry, you cannot destroy the **#{@member.user.login}'s** membership"
    end
    redirect_to group_members_path(@group)
  end

  def check_permissions
    @group = Group.find_by_slug_or_id(params[:id]) || current_group

    if !current_user.owner_of?(@group)
      flash[:error] = t("global.permission_denied")
      redirect_to group_path(@group)
    end
  end
end
