class AnswersController < ApplicationController
  before_filter :login_required

  def create
    @answer = Answer.new(params[:answer])
    @question = Question.find(params[:question_id])
    @answer.question = @question
    @answer.user = current_user

    if @answer.save
      @question.answer_added!

      flash[:notice] = "Thanks!"
      redirect_to question_path(@question)
    else
      flash[:notice] = "Something went wrong adding your answer"
      redirect_to question_path(@question)
    end
  end

  def edit
    @answer = Answer.find(params[:id])
    @question = @answer.question
  end

  def update
    @answer = Answer.find(params[:id])

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
    @answer = Answer.find(params[:id])
    @question = @answer.question
    @answer.destroy

    respond_to do |format|
      format.html { redirect_to(question_path(@question)) }
      format.xml  { head :ok }
    end
  end
end
