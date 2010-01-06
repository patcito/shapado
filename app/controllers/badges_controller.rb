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

  # GET /badges/new
  # GET /badges/new.xml
  def new
    @badge = Badge.new

    respond_to do |format|
      format.html # new.html.erb
      format.json  { render :json => @badge.to_json }
    end
  end

  # GET /badges/1/edit
  def edit
    @badge = Badge.find(params[:id])
  end

  # POST /badges
  # POST /badges.xml
  def create
    @badge = Badge.new(params[:badge])

    respond_to do |format|
      if @badge.save
        flash[:notice] = 'Badge was successfully created.'
        format.html { redirect_to(@badge) }
        format.json { render :json => @badge, :status => :created, :location => @badge }
      else
        format.html { render :action => "new" }
        format.json  { render :json => @badge.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /badges/1
  # PUT /badges/1.xml
  def update
    @badge = Badge.find(params[:id])

    respond_to do |format|
      if @badge.update_attributes(params[:badge])
        flash[:notice] = 'Badge was successfully updated.'
        format.html { redirect_to(@badge) }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.json  { render :json => @badge.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /badges/1
  # DELETE /badges/1.xml
  def destroy
    @badge = Badge.find(params[:id])
    @badge.destroy

    respond_to do |format|
      format.html { redirect_to(badges_url) }
      format.json  { head :ok }
    end
  end
end
