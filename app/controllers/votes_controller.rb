class VotesController < ApplicationController
  before_filter :login_required

  def create
    vote = Vote.new
    if params[:vote_up]
      vote.value = 1
    elsif params[:vote_down]
      vote.value = -1
    end
    vote.voteable_type = params[:voteable_type]
    vote.voteable_id = params[:voteable_id]
    vote.user = current_user

    if vote.save
      vote.voteable.add_vote!(vote.value)
    else
      flash[:error] = vote.errors.full_messages.join(", ")
    end

    redirect_to params[:source]
  end
end
