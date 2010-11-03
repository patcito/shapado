class GroupsController < ApplicationController
  skip_before_filter :check_group_access, :only => [:logo, :css, :favicon]
  before_filter :login_required, :except => [:index, :show, :logo, :css, :favicon]
  before_filter :check_permissions, :only => [:edit, :update, :close]
  before_filter :moderator_required , :only => [:accept, :destroy]
  subtabs :index => [ [:most_active, "activity_rate desc"], [:newest, "created_at desc"],
                      [:oldest, "created_at asc"], [:name, "name asc"]]
  # GET /groups
  # GET /groups.json
  def index
    @state = "active"
    case params.fetch(:tab, "active")
      when "pendings"
        @state = "pending"
    end

    options = {:per_page => params[:per_page] || 15,
               :page => params[:page],
               :state => @state,
               :order => current_order,
               :private => false}

    if params[:q].blank?
      @groups = Group.paginate(options)
    else
      @groups = Group.filter(params[:q], options)
    end

    respond_to do |format|
      format.html # index.html.haml
      format.json  { render :json => @groups }
      format.js do
        html = render_to_string(:partial => "group", :collection  => @groups)
        pagination = render_to_string(:partial => "shared/pagination", :object => @groups,
                                      :format => "html")
        render :json => {:html => html, :pagination => pagination }
      end
    end
  end

  # GET /groups/1
  # GET /groups/1.json
  def show
    @active_subtab = "about"

    if params[:id]
      @group = Group.find_by_slug_or_id(params[:id])
    else
      @group = current_group
    end
    raise PageNotFound if @group.nil?

    @comments = @group.comments.paginate(:page => params[:page].to_i,
                                         :per_page => params[:per_page] || 10 )

    @comment = Comment.new


    respond_to do |format|
      format.html # show.html.erb
      format.json  { render :json => @group }
    end
  end

  # GET /groups/new
  # GET /groups/new.json
  def new
    @group = Group.new

    respond_to do |format|
      format.html # new.html.erb
      format.json  { render :json => @group }
    end
  end

  # GET /groups/1/edit
  def edit
  end

  # POST /groups
  # POST /groups.json
  def create
    @group = Group.new
    @group.safe_update(%w[name legend description default_tags subdomain logo forum enable_latex
                          custom_favicon language theme custom_css wysiwyg_editor], params[:group])

    @group.safe_update(%w[isolate domain private], params[:group]) if current_user.admin?

    @group.owner = current_user
    @group.state = "active"

    @group.widgets << TagCloudWidget.new
    @group.widgets << TopUsersWidget.new
    @group.widgets << BadgesWidget.new

    respond_to do |format|
      if @group.save
        @group.add_member(current_user, "owner")
        flash[:notice] = I18n.t("groups.create.flash_notice")
        format.html { redirect_to(domain_url(:custom => @group.domain, :controller => "admin/manage", :action => "properties")) }
        format.json  { render :json => @group.to_json, :status => :created, :location => @group }
      else
        format.html { render :action => "new" }
        format.json { render :json => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.json
  def update
    @group.safe_update(%w[name legend description default_tags subdomain logo logo_info forum enable_latex
                          custom_favicon language theme reputation_rewards reputation_constrains
                          has_adult_content registered_only openid_only custom_css wysiwyg_editor fb_button share], params[:group])

    @group.safe_update(%w[isolate domain private has_custom_analytics has_custom_html has_custom_js], params[:group]) #if current_user.admin?
    @group.safe_update(%w[analytics_id analytics_vendor], params[:group]) if @group.has_custom_analytics
    @group.custom_html.update_attributes(params[:group][:custom_html] || {}) if @group.has_custom_html

    respond_to do |format|
      if @group.save
        flash[:notice] = 'Group was successfully updated.' # TODO: i18n
        format.html { redirect_to(params[:source] ? params[:source] : group_path(@group)) }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.json  { render :json => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.json
  def destroy
    @group = Group.find_by_slug_or_id(params[:id])
    @group.destroy

    respond_to do |format|
      format.html { redirect_to(groups_url) }
      format.json  { head :ok }
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
    @group = Group.find_by_slug_or_id(params[:id], :select => [:file_list])
    if @group && @group.has_logo?
      send_data(@group.logo.try(:read), :filename => "logo.#{@group.logo.extension}", :type => @group.logo.content_type,  :disposition => 'inline')
    else
      render :text => ""
    end
  end

  def css
    @group = Group.find_by_slug_or_id(params[:id], :select => [:file_list])
    if @group && @group.has_custom_css?
      send_data(@group.custom_css.read, :filename => "custom_theme.css", :type => "text/css")
    else
      render :text => ""
    end
  end

  def favicon
    @group = Group.find_by_slug_or_id(params[:id], :select => [:file_list])
    if @group && @group.has_custom_favicon?
      send_data(@group.custom_favicon.read, :filename => "favicon.ico", :type => @group.custom_favicon.content_type)
    else
      render :text => ""
    end
  end

  def autocomplete_for_group_slug
    @groups = Group.all( :limit => params[:limit] || 20,
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
