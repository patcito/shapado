class AdsController < ApplicationController
  before_filter :login_required
  before_filter :check_permissions
  before_filter :check_has_custom_ads
  layout "manage"
  tabs :default => :ads

  def new
    @ad = params[:type].classify.constantize.new
  end

  def index
    @ads = current_group.ads
  end

  # POST /ads
  # POST /ads.xml
  def create
    if ['Adsense', 'Adbard'].include? params["ad"]["_type"]
      @ad = params["ad"]["_type"].camelize.constantize.new
      case @ad
        when Adsense
          @ad.safe_update(%w[name position google_ad_client google_ad_slot
                                    google_ad_width google_ad_height], params[:ad])
        when Adbard
          @ad.safe_update(%w[name position adbard_host_id adbard_site_key], params[:ad])
      end
      @ad.group = current_group

      respond_to do |format|
        if @ad.save
          flash[:notice] = t('ads.create.success')
          format.html { redirect_to(ads_path) }
          format.xml  { render :xml => @ad, :status => :created, :location => @ad }
        else
          format.html { render :action => "new", :controller => "ads" }
          format.xml  { render :xml => @ad.errors, :status => :unprocessable_entity }
        end
      end
    else
      respond_to do |format|
        format.html { render :action => "new", :controller => "ads" }
        format.xml  { render :xml => @ad.errors, :status => :unprocessable_entity }
      end
    end
  end


  # DELETE /ads/1
  # DELETE /ads/1.xml
  def destroy
    @ad = Ad.find_by_slug(params[:id])
    @ad.destroy

    respond_to do |format|
      format.html { redirect_to(ads_url) }
      format.xml  { head :ok }
    end
  end

  private
    def check_has_custom_ads
      unless current_group.has_custom_ads
        redirect_to current_group
      end
    end

    def check_permissions
      @group = current_group

      if @group.nil?
        redirect_to groups_path
      elsif !current_user.owner_of?(@group) && !current_user.admin?
        flash[:error] = t("global.permission_denied")
        redirect_to ads_path
      end
    end
end
