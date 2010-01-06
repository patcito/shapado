class GroupsController < ApplicationController
  skip_before_filter :check_group_access, :only => [:logo]
  before_filter :login_required, :except => [:index, :show, :logo]
  before_filter :check_permissions, :only => [:edit, :update, :close]
  before_filter :moderator_required , :only => [:accept, :destroy]
  # GET /groups
  # GET /groups.xml
  def index
    case params.fetch(:tab, "actives")
      when "actives"
        @state = "active"
      when "pendings"
        @state = "pending"
    end

    @groups = Group.paginate(:per_page => 15,
                             :page => params[:page],
                             :state => @state,
                             :private => false)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @groups }
    end
  end

  # GET /groups/1
  # GET /groups/1.xml
  def show
    @active_subtab = "about"
    if params[:id]
      @group = Group.find_by_slug_or_id(params[:id])
    else
      @group = current_group
    end

    respond_to do |format|
      format.html do
        if @group.isolate
          render :template => 'groups/isolate'
        else
          render
        end
      end# show.html.erb
      format.xml  { render :xml => @group }
    end
  end

  # GET /groups/new
  # GET /groups/new.xml
  def new
    @group = Group.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @group }
    end
  end

  # GET /groups/1/edit
  def edit
  end

  # POST /groups
  # POST /groups.xml
  def create
    @group = Group.new
    @group.safe_update(%w[name legend description default_tags subdomain logo_data
                          language theme], params[:group])
    @group.safe_update(%w[isolate domain private], params[:group]) if current_user.admin?

    @group.owner = current_user

    respond_to do |format|
      if @group.save
        @group.add_member(current_user, "owner")
        if data = params[:group][:logo_data]
          @group.logo_data = data
        end
        flash[:notice] = 'Group was successfully created.'
        format.html { redirect_to(@group) }
        format.xml  { render :xml => @group, :status => :created, :location => @group }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.xml
  def update
    @group.safe_update(%w[name legend description default_tags subdomain logo_data
                          language theme], params[:group])
    @group.safe_update(%w[isolate domain private has_custom_analytics], params[:group]) if current_user.admin?
    @group.safe_update(%w[analytics_id analytics_vendor], params[:group]) if @group.has_custom_analytics

    respond_to do |format|
      if @group.save
        flash[:notice] = 'Group was successfully updated.'
        format.html { redirect_to(@group) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.xml
  def destroy
    @group = Group.find_by_slug_or_id(params[:id])
    @group.destroy

    respond_to do |format|
      format.html { redirect_to(groups_url) }
      format.xml  { head :ok }
    end
  end

  def accept
    @group = Group.find_by_slug_or_id(params[:id])
    @group.has_custom_ads = true if params["has_custom_ads"] == "true"
    @group.state = "active"
    @group.save
    redirect_to group_path(@group)
  end

  def close
    @group.state = "closed"
    @group.save
    redirect_to group_path(@group)
  end

  def logo
    @group = Group.find_by_slug_or_id(params[:id])
    send_data(@group.logo.raw, :filename => @group.logo.filename,  :disposition => 'inline')
  end

  def autocomplete_for_group_slug
    @groups = Group.find(:all, :limit => params[:limit] || 20,
                             :fields=> 'slug',
                             :slug =>  /.*#{params[:prefix].downcase.to_s}.*/,
                             :order => "slug desc",
                             :state => "active")

    respond_to do |format|
      format.json {render :json=>@groups}
    end
  end

  def allow_custom_ads
    if current_user.admin?
      @group = Group.find_by_slug_or_id(params[:id])
      @group.has_custom_ads = true
      @group.save
    end
    redirect_to groups_path
  end

  def disallow_custom_ads
    if current_user.admin?
      @group = Group.find_by_slug_or_id(params[:id])
      @group.has_custom_ads = false
      @group.save
    end
    redirect_to groups_path
  end

  protected
  def check_permissions
    @group = Group.find_by_slug_or_id(params[:id])

    if @group.nil?
      redirect_to groups_path
    elsif !current_user.owner_of?(@group)
      flash[:error] = t("global.permission_denied")
      redirect_to group_path(@group)
    end
  end
end
