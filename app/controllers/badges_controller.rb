class BadgesController < ApplicationController

  tabs :default => :badges

  # GET /badges
  # GET /badges.xml
  def index
    @badges = Badge.all

    respond_to do |format|
      format.html # index.html.erb
      format.json  { render :json => @badges.to_json }
    end
  end

  # GET /badges/1
  # GET /badges/1.xml
  def show
    user_ids = Badge.paginate(:token => params[:id], :group_id => current_group.id,
                   :order => "created_at desc", :select => [:user_id]).map do |b| b.user_id end
    @users = User.find(user_ids)
    @badge = Badge.new(:token => params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json  { render :json => @badge.to_json }
    end
  end
end
