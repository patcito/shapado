class FlagsController < ApplicationController
#   before_filter :check_permissions

  def create
    flag = Flag.new
    flag.safe_update(%w[flaggeable_type flaggeable_id type], params[:flag])
    flagged = false
    if flag.flaggeable.user != current_user
      flag.user = current_user
      if flag.save
        flagged = true
        flag.flaggeable.flagged!
        flash[:notice] = "thanks for your report"
      else
        flash[:error] = flag.errors.full_messages.join(", ")
      end
    else
      flash[:error] = "You cannot flag this"
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
