class FlagsController < ApplicationController
  before_filter :login_required

  def create
    flag = Flag.new
    flag.safe_update(%w[flaggeable_type flaggeable_id type], params[:flag])
    flag.group = current_group

    flagged = false

    if flag.flaggeable.user != current_user
      flag.user = current_user
      if flag.save
        flagged = true
        flag.flaggeable.flagged!
        flash[:notice] = t(:flash_notice, :scope => "flags.create")

        Magent.push("actors.judge", :on_flag, flag.id)
      else
        flash[:error] = flag.errors.full_messages.join(", ")
      end
    else
      flash[:error] = t(:flash_error, :scope => "flags.create")
    end

    respond_to do |format|
      format.html{redirect_to params[:flag][:return_to]}

      format.json do
        if flagged
          render(:json => {:status => :ok,
                           :message => flash[:notice]}.to_json)
        else
          render(:json => {:status => :error, :message => flash[:error] }.to_json)
        end
      end
    end
  end
end

