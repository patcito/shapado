class GroupsController < ApplicationController
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
                             :conditions => {:state => @state})

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @groups }
    end
  end

  # GET /groups/1
  # GET /groups/1.xml
  def show
    @group = Group.find_by_slug_or_id(params[:id])

    respond_to do |format|
      format.html # show.html.erb
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
    @group.safe_update(%w[name description legend categories subdomain], params[:group])
    @group.owner = current_user

    respond_to do |format|
      if @group.save
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
    @group.safe_update(%w[name legend description categories logo_data], params[:group])

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
    send_data(@group.logo.raw, :type => "image/png",  :disposition => 'inline')
  end

  protected
    def check_permissions
    @group = Group.find_by_slug_or_id(params[:id])

    if @group.nil?
      redirect_to groups_path
    elsif !current_user.can_modify?(@group)
      flash[:error] = t("views.layout.permission_denied")
      redirect_to group_path(@group)
    end
  end
end
