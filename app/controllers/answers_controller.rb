class AnswersController < ApplicationController
  before_filter :login_required, :except => :show
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
      @answer.group_id = @question.group_id
    end

    if @question && @answer.save
      unless @answer.comment?
        @question.answer_added!
        # TODO: use mangent to do it
        users = User.find(@question.watchers, :fields => ["email", "notification_opts"]) || []
        users.push(@question.user)
        users.each do |u|
          email = u.email
          if !email.blank? && u.notification_opts["new_answer"] == "1"
            Notifier.deliver_new_answer(u, current_group, @answer)
          end
        end
        current_user.on_activity(:answer_question, current_group)
      else
        current_user.on_activity(:comment_question, current_group)
      end

      flash[:notice] = t(:flash_notice, :scope => "answers.create")
      redirect_to question_path(current_languages, @question)
    else
      flash[:error] = t(:flash_error, :scope => "answers.create")
      redirect_to question_path(current_languages, @question)
    end
  end

  def edit
    @question = @answer.question
  end

  def update
    respond_to do |format|
      @answer.safe_update(%w[parent_id body], params[:answer])
      if @answer.valid? && @answer.save
        flash[:notice] = t(:flash_notice, :scope => "answers.update")
        format.html { redirect_to(question_path(current_languages, @answer.question)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @answer.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @question = @answer.question
    @answer.user.update_reputation(:delete_answer, current_group)
    @answer.destroy
    @question.answer_removed!

    respond_to do |format|
      format.html { redirect_to(question_path(current_languages, @question)) }
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
      flash[:error] = t("global.permission_denied")
      redirect_to questions_path(current_languages)
    end
  end
end
