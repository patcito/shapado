class ImportsController < ApplicationController
  before_filter :login_required
  before_filter :owner_required

  tabs :default => :imports
  subtabs :index => [[:need_confirmation, "need_confirmation"],
                       ]

  def index
    @active_subtab ||= 'need_confirmation'

    case @active_subtab.to_s
    when 'need_confirmation'
      @users = current_group.users(:needs_confirmation => true, :order => "created_at desc", :select => [:name, :login, :email])
    end
  end

  def send_confirmation
    @users = if params[:all]
      current_group.users(:needs_confirmation => true, :select => [:email, :login, :name])
    else
      [User.first(:_id => params[:user_id], :select => [:email, :login, :name])]
    end

    @users.each do |user|
      user.instance_variable_set("@group", current_group)
      user.send_reset_password_instructions
      user.set(:needs_confirmation => false)
    end

    respond_to do |format|
      format.html { redirect_to imports_path }
    end
  end
end
