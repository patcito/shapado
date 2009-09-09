class AnswersController < ApplicationController
  before_filter :login_required
  before_filter :check_permissions, :only => [:edit, :update, :destroy]

  helper :votes

  def show
    @answer = Answer.find(params[:id])
    @question = @answer.question
  end

  def create
    @answer = Answer.new
    @answer.safe_update(%w[parent_id body], params[:answer])
    @answer.user = current_user

    @question = Question.find(params[:question_id])

    if @answer.parent_id.blank?
      @answer.question = @question
    end

    if @question && @answer.save
      unless @answer.comment?
        @question.answer_added!
        email = @question.user.email
        if !email.blank? && @question.user.notification_opts["new_answer"] == "1"
          Notifier.deliver_new_answer(@question.user, @answer)
        end
        current_user.update_reputation(:answer_question)
      else
        current_user.update_reputation(:comment_question)
      end

      flash[:notice] = t(:flash_notice, :scope => "views.answers.create")

      redirect_to question_path(@question)
    else
      flash[:error] = t(:flash_error, :scope => "views.answers.create")
      redirect_to question_path(@question)
    end
  end

  def edit
    @question = @answer.question
  end

  def update
    respond_to do |format|
      @answer.safe_update(%w[parent_id body], params[:answer])
      if @answer.valid? && @answer.save
        flash[:notice] = t(:flash_notice, :scope => "views.answers.update")
        format.html { redirect_to(@answer.question) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @answer.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @question = @answer.question
    @answer.destroy
    @question.answer_removed!

    respond_to do |format|
      format.html { redirect_to(question_path(@question)) }
      format.xml  { head :ok }
    end
  end

  def flag
    @answer = Answer.find(params[:id])
    @flag = Flag.new
    @flag.flaggeable_type = @answer.class.name
    @flag.flaggeable_id = @answer.id
    respond_to do |format|
      format.html
    end
  end

  protected
  def check_permissions
    @answer = Answer.find(params[:id])
    if @answer.nil? || !current_user.can_modify?(@answer)
      flash[:error] = t("views.layout.permission_denied")
      redirect_to questions_path
    end
  end
end
