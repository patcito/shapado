class BadgesController < ApplicationController

  tabs :default => :badges

  # GET /badges
  # GET /badges.xml
  def index
    @badges = []
    Badge.TOKENS.each do |token|
     badge = Badge.new(:token => token)
     badge["count"] = Badge.count(:token => token, :group_id => current_group.id)
     @badges << badge
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json  { render :json => @badges }
    end
  end

  # GET /badges/1
  # GET /badges/1.xml
  def show
    @badge = Badge.new(:token => params[:id])
    @badge[:type] ||= (@badge.type || params[:type] || "bronze")

    @badges = Badge.paginate(:token => @badge.token, :group_id => current_group.id,
                             :type => @badge.type,
                             :order => "created_at desc", :select => [:user_id],
                             :page => params[:page] || 1, :per_page => 25)

    user_ids = @badges.map { |b| b.user_id }
    @users = User.find(user_ids)

    respond_to do |format|
      format.html # show.html.erb
      format.json  { render :json => @badge.to_json }
    end
  end
end
