class WidgetsController < ApplicationController
  before_filter :login_required
  before_filter :check_permissions
  layout "manage"
  tabs :default => :widgets

  # GET /widgets
  # GET /widgets.json
  def index
    @widget = Widget.new
    @widgets = @group.widgets
  end

  # POST /widgets
  # POST /widgets.json
  def create
    if Widget.types.include?(params[:widget][:_type])
      @widget = params[:widget][:_type].constantize.new
    end

    @group.widgets << @widget

    respond_to do |format|
      if @widget.valid? && @group.save
        flash[:notice] = 'Widget was successfully created.'
        format.html { redirect_to widgets_path }
        format.json  { render :json => @widget.to_json, :status => :created, :location => widget_path(:id => @widget.id) }
      else
        format.html { render :action => "index" }
        format.json  { render :json => @widget.errors, :status => :unprocessable_entity }
      end
    end
  end


  # DELETE /ads/1
  # DELETE /ads/1.json
  def destroy
    @widget = @group.widgets.find(params[:id])
    @group.widgets.delete(@widget)
    @group.save

    respond_to do |format|
      format.html { redirect_to(widgets_url) }
      format.json  { head :ok }
    end
  end

  def move
    widget = @group.widgets.find(params[:id])
    widget.move_to(params[:move_to])
    redirect_to widgets_path
  end

  private
  def check_permissions
    @group = current_group

    if @group.nil?
      redirect_to groups_path
    elsif !current_user.owner_of?(@group)
      flash[:error] = t("global.permission_denied")
      redirect_to ads_path
    end
  end
end
