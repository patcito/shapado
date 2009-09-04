class VotesController < ApplicationController
  before_filter :check_permissions

  def create
    vote = Vote.new
    if params[:vote_up]
      vote.value = 1
    elsif params[:vote_down]
      vote.value = -1
    end
    vote.voteable_type = params[:voteable_type]
    vote.voteable_id = params[:voteable_id]
    voted = false
    if vote.voteable.user != current_user
      vote.user = current_user
      if vote.save
        vote.voteable.add_vote!(vote.value, current_user)
        voted = true
        flash[:notice] = t(:flash_notice, :scope => "views.votes.create")
      else
        flash[:error] = vote.errors.full_messages.join(", ")
      end
    else
      flash[:error] = "#{t(:flash_error, :scope => "views.votes.create")} "
      flash[:error] += t(params[:voteable_type].downcase, :scope => "activerecord.models").downcase
    end


    respond_to do |format|
      format.html{redirect_to params[:source]}

      format.json do
        if voted
          average = vote.voteable.votes_average+(vote.value)
          content = "#{average} #{t(:votes, :scope => "activerecord.models")}"
          render(:json => {:status => :ok,
                           :message => flash[:notice],
                           :content => content}.to_json)
        else
          render(:json => {:status => :error, :message => flash[:error] }.to_json)
        end
      end
    end
  end

  protected
  def check_permissions
    unless logged_in?
      flash[:error] = t(:unauthenticated, :scope => "views.votes.create")
      flash[:error] += ", #{t(:please_login, :scope => "views.layout")}"
      respond_to do |format|
        format.html{redirect_to params[:source]}
        format.json{render(:json => {:status => :error, :message => flash[:error] }.to_json)}
      end
    end
  end

end
