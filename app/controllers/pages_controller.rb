class PagesController < ApplicationController
  # GET /pages
  # GET /pages.json
  def index
    @pages = current_group.pages

    respond_to do |format|
      format.html # index.html.haml
      format.json  { render :json => @pages }
    end
  end

  # GET /pages/1
  # GET /pages/1.json
  def show
    @page = current_group.pages.by_slug(params[:id])

    respond_to do |format|
      format.html # show.html.haml
      format.json  { render :json => @page }
    end
  end

  # GET /pages/new
  # GET /pages/new.json
  def new
    @page = Page.new

    respond_to do |format|
      format.html # new.html.haml
      format.json  { render :json => @page }
    end
  end

  # GET /pages/1/edit
  def edit
    @page = current_group.pages.by_slug(params[:id])
  end

  # POST /pages
  # POST /pages.json
  def create
    @page = Page.new
    @page.safe_update(%w[title body tags wiki language adult_content css js], params[:page])
    @page.group = current_group
    @page.user = current_user

    respond_to do |format|
      if @page.save
        flash[:notice] = 'Page was successfully created.'
        format.html { redirect_to(@page) }
        format.json  { render :json => @page, :status => :created, :location => @page }
      else
        format.html { render :action => "new" }
        format.json  { render :json => @page.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /pages/1
  # PUT /pages/1.json
  def update
    @page = current_group.pages.by_slug(params[:id])
    @page.safe_update(%w[title body tags wiki language adult_content css js], params[:page])
    @page.updated_by = current_user

    respond_to do |format|
      if @page.save
        flash[:notice] = 'Page was successfully updated.'
        format.html { redirect_to(@page) }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.json  { render :json => @page.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /pages/1
  # DELETE /pages/1.json
  def destroy
    @page = current_group.pages.find(params[:id])
    @page.destroy

    respond_to do |format|
      format.html { redirect_to(pages_url) }
      format.json  { head :ok }
    end
  end
end
