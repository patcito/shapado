class AnnouncementsController < ApplicationController
  # GET /announcements
  # GET /announcements.json
  def index
    @announcements = current_group.announcements.paginate(:page => params[:page],
                                                          :per_page => params[:per_page])

    respond_to do |format|
      format.html # index.html.haml
      format.json  { render :json => @announcements }
    end
  end

  # GET /announcements/1
  # GET /announcements/1.json
  def show
    @announcement = current_group.announcements.find(params[:id])

    respond_to do |format|
      format.html # show.html.haml
      format.json  { render :json => @announcement }
    end
  end

  # GET /announcements/new
  # GET /announcements/new.json
  def new
    @announcement = Announcement.new

    respond_to do |format|
      format.html # new.html.haml
      format.json  { render :json => @announcement }
    end
  end

  # GET /announcements/1/edit
  def edit
    @announcement = current_group.announcements.find(params[:id])
  end

  # POST /announcements
  # POST /announcements.json
  def create
    @announcement = Announcement.new(params[:announcement])

    respond_to do |format|
      if @announcement.save
        flash[:notice] = 'Announcement was successfully created.'
        format.html { redirect_to(@announcement) }
        format.json  { render :json => @announcement, :status => :created, :location => @announcement }
      else
        format.html { render :action => "new" }
        format.json  { render :json => @announcement.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /announcements/1
  # PUT /announcements/1.json
  def update
    @announcement = current_group.announcements.find(params[:id])

    respond_to do |format|
      if @announcement.update_attributes(params[:announcement])
        flash[:notice] = 'Announcement was successfully updated.'
        format.html { redirect_to(@announcement) }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.json  { render :json => @announcement.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /announcements/1
  # DELETE /announcements/1.json
  def destroy
    @announcement = current_group.announcements.find(params[:id])
    @announcement.destroy

    respond_to do |format|
      format.html { redirect_to(announcements_url) }
      format.json  { head :ok }
    end
  end

  def hide
    session[:announcement_hide_time] = Time.now.to_i

    respond_to do |format|
      format.html { redirect_to root_path }
      format.js { render :json => {:status => "ok"} }
    end
  end
end
