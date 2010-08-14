class Admin::ManageController < ApplicationController
  before_filter :login_required
  before_filter :check_permissions
  layout "manage"
  tabs :dashboard => :dashboard,
       :properties => :properties,
       :content => :content,
       :theme => :theme,
       :actions => :actions,
       :stats => :stats,
       :widgets => :widgets

  subtabs :properties => [[:general, "general"],
                          [:share, "share"],
                          [:rewards, "rewards"],
                          [:constrains, "constrains"],
                          [:theme, "theme"],
                          [:domain, "domain"]]
  subtabs :content => [[:question_prompt, "question_prompt"],
                       [:question_help, "question_help"],
                       [:head_tag, "head_tag"],
                       [:head, "head"], [:footer, "footer"],
                       [:top_bar, "top_bar"]]

  def dashboard
  end

  def properties
    @active_subtab ||= "general"
  end

  def actions
  end

  def stats
  end

  def domain
  end

  def content
    unless @group.has_custom_html
      flash[:error] = t("global.permission_denied")
      redirect_to domain_url(:custom => @group.domain, :controller => "manage",
                             :action => "properties")
    end
  end

  protected
  def check_permissions
    @group = current_group

    if @group.nil?
      redirect_to groups_path
    elsif !current_user.owner_of?(@group) && !current_user.admin?
      flash[:error] = t("global.permission_denied")
      redirect_to domain_url(:custom => @group.domain)
    end
  end
end
