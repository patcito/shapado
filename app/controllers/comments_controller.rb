class CommentsController < ApplicationController
  before_filter :check_permissions

  def create
    comment = Comment.new
    comment.body = params[:body]
    comment.commentable_type = params[:commentable_type]
    comment.commentable_id = params[:commentable_id]
    comment.user = current_user

    if comment.save
      flash[:notice] = t("comments.create.flash_notice")
    else
      flash[:error] = comment.errors.full_messages.join(", ")
    end

    respond_to do |format|
      format.html{redirect_to params[:source]}
    end
  end


  def check_permissions
  end
end
