class CommentsController < ApplicationController
  before_filter :login_required
  before_filter :find_scope
  before_filter :check_permissions, :except => [:create]

  def create
    @comment = Comment.new
    @comment.body = params[:body]
    @comment.commentable = scope
    @comment.user = current_user
    @comment.group = current_group

    if saved = @comment.save
      current_user.on_activity(:comment_question, current_group)
      Magent.push("actors.judge", :on_comment, @comment.id)

      if question_id = @comment.question_id
        Question.update_last_target(question_id, @comment)
      end

      flash[:notice] = t("comments.create.flash_notice")
    else
      flash[:error] = @comment.errors.full_messages.join(", ")
    end

    # TODO: use magent to do it
    if (question = @comment.find_question) && (recipient = @comment.find_recipient)
      email = recipient.email
      if !email.blank? && current_user.id != recipient.id && recipient.notification_opts.new_answer
        Notifier.deliver_new_comment(current_group, @comment, recipient, question)
      end
    end

    respond_to do |format|
      if saved
        format.html {redirect_to params[:source]}
        format.json {render :json => @comment.to_json, :status => :created}
        format.js do
          render(:json => {:success => true, :message => flash[:notice],
            :html => render_to_string(:partial => "comments/comment",
                                      :object => @comment,
                                      :locals => {:source => params[:source], :mini => true})}.to_json)
        end
      else
        format.html {redirect_to params[:source]}
        format.json {render :json => @comment.errors.to_json, :status => :unprocessable_entity }
        format.js {render :json => {:success => false, :message => flash[:error] }.to_json }
      end
    end
  end

  def edit
    @comment = current_scope.find(params[:id])
    respond_to do |format|
      format.html
      format.js do
        render :json => {:status => :ok,
         :html => render_to_string(:partial => "comments/edit_form",
                                   :locals => {:source => params[:source],
                                               :commentable => @comment.commentable})
        }
      end
    end
  end

  def update
    respond_to do |format|
      @comment = Comment.find(params[:id])
      @comment.body = params[:body]
      if @comment.valid? && @comment.save
        if question_id = @comment.question_id
          Question.update_last_target(question_id, @comment)
        end

        flash[:notice] = t(:flash_notice, :scope => "comments.update")
        format.html { redirect_to(params[:source]) }
        format.json { render :json => @comment.to_json, :status => :ok}
        format.js { render :json => { :message => flash[:notice],
                                      :success => true,
                                      :body => @comment.body} }
      else
        flash[:error] = @comment.errors.full_messages.join(", ")
        format.html { render :action => "edit" }
        format.json { render :json => @comment.errors, :status => :unprocessable_entity }
        format.js { render :json => { :success => false, :message => flash[:error]}.to_json }
      end
    end
  end

  def destroy
    @comment = scope.comments.find(params[:id])
    @comment.destroy

    respond_to do |format|
      format.html { redirect_to(params[:source]) }
      format.json { head :ok }
    end
  end

  protected
  def check_permissions
    @comment = current_scope.find(params[:id])
    valid = false
    if params[:action] == "destroy"
      valid = @comment.can_be_deleted_by?(current_user)
    else
      valid = current_user.can_modify?(@comment)
    end

    if !valid
      respond_to do |format|
        format.html do
          flash[:error] = t("global.permission_denied")
          redirect_to params[:source] || questions_path
        end
        format.json { render :json => {:message => t("global.permission_denied")}, :status => :unprocessable_entity }
      end
    end
  end

  def current_scope
    scope.comments
  end

  def find_scope
    @question = Question.by_slug(params[:question_id])
    @answer = @question.answers.find(params[:answer_id]) unless params[:answer_id].blank?
  end

  def scope
    unless @answer.nil?
      @answer
    else
      @question
    end
  end

  def full_scope
    unless @answer.nil?
      [@question, @answer]
    else
      [@question]
    end
  end
  helper_method :full_scope

end
