class Admin::ManageController < ApplicationController
  before_filter :login_required
  before_filter :check_permissions
  layout "manage"
  tabs :dashboard => :dashboard,
       :properties => :properties,
       :actions => :actions,
       :stats => :stats

  def dashboard
  end

  def properties
  end

  def actions
  end

  def stats
  end

  protected
  def check_permissions
    @group = current_group

    if @group.nil?
      redirect_to groups_path
    elsif !current_user.owner_of?(@group) && !current_user.admin?
      flash[:error] = t("global.permission_denied")
      redirect_to  domain_url(:custom => @group.domain)
    end
  end
end
