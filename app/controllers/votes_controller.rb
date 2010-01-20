class VotesController < ApplicationController
  before_filter :check_permissions

  def create
    vote = Vote.new
    vote_type = ""
    if params[:vote_up]
      vote_type = "vote_up"
      vote.value = 1
    elsif params[:vote_down]
      vote_type = "vote_down"
      vote.value = -1
    end


    vote.voteable_type = params[:voteable_type]
    vote.voteable_id = params[:voteable_id]
    vote.group = vote.voteable.group

    voted = false
    if vote.voteable.user != current_user
      user_vote = current_user.vote_on(vote.voteable)
      if user_vote && (user_vote.value != vote.value)
        vote.voteable.remove_vote!(user_vote.value, current_user)
        vote.voteable.add_vote!(vote.value, current_user)
        user_vote.value = vote.value
        voted = true
        user_vote.save!
        flash[:notice] = t("votes.create.flash_notice")
      else
        vote.user = current_user
        if vote.save
          vote.voteable.add_vote!(vote.value, current_user)
          voted = true
          flash[:notice] = t("votes.create.flash_notice")
        else
          flash[:error] = vote.errors.full_messages.join(", ")
        end
      end
    else
      flash[:error] = "#{t(:flash_error, :scope => "votes.create")} "
      flash[:error] += t(params[:voteable_type].downcase, :scope => "activerecord.models").downcase
    end

    if voted
      Magent.push("actors.judge", :on_vote, vote.id)
    end

    respond_to do |format|
      format.html{redirect_to params[:source]}

      format.json do
        if voted
          average = vote.voteable.reload.votes_average
          render(:json => {:status => :ok,
                           :message => flash[:notice],
                           :vote_type => vote_type,
                           :average => average}.to_json)
        else
          render(:json => {:status => :error, :message => flash[:error] }.to_json)
        end
      end
    end
  end

  def destroy
    @vote = Vote.find(params[:id])
    voteable = @vote.voteable
    value = @vote.value
    if  @vote && current_user == @vote.user
      @vote.destroy
      voteable.remove_vote!(value, current_user)
    end
    respond_to do |format|
      format.html { redirect_to params[:source] }
      format.json  { head :ok }
    end
  end

  protected
  def check_permissions
    unless logged_in?
      flash[:error] = t(:unauthenticated, :scope => "votes.create")
      respond_to do |format|
        format.html do
          flash[:error] += ", [#{t("global.please_login")}](#{login_path})"
          redirect_to params[:source]
        end
        format.json do
          flash[:error] += ", <a href='#{login_path}'> #{t("global.please_login")} </a>"
          render(:json => {:status => :error, :message => flash[:error] }.to_json)
        end
      end
    end
  end

end
