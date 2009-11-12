class GroupMembersController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  before_filter :check_permissions, :only => [:edit, :update]

  def index
    @group = Group.find_by_slug_or_id(params[:group_id])
    @members = @group.memberships.paginate(:page => params[:page] || 1,
                                           :per_page => params[:per_page] || 25)
  end

  def create
  end

  def update
  end
end
