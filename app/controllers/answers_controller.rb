class AnswersController < ApplicationController
  before_filter :login_required
  before_filter :check_permissions, :only => [:edit, :update, :destroy]

  def create
    @answer = Answer.new(params[:answer])
    @answer.user = current_user

    @question = Question.find(params[:question_id])

    if @answer.parent_id.blank?
      @answer.question = @question
    end

    if @question && @answer.save
      if !@answer.parent_id.blank?
        @question.answer_added!
        current_user.update_reputation(:answer_question)
      end

      flash[:notice] = "Thanks!"
      redirect_to question_path(@question)
    else
      flash[:notice] = "Something went wrong adding your answer"
      redirect_to question_path(@question)
    end
  end

  def edit
    @question = @answer.question
  end

  def update
    respond_to do |format|
      if @answer.update_attributes(params[:answer])
        flash[:notice] = 'Answer was successfully updated.'
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

  protected
  def check_permissions
    @answer = Answer.find(params[:id])
    if @answer.nil? || !current_user.can_modify?(@answer)
      flash[:error] = "Permission denied"
      redirect_to questions_path
    end
  end
end
