class AnswersController < ApplicationController
  def create
    @answer = Answer.new(params[:answer])
    @question = Question.find(params[:question_id])
    @answer.question = @question
    @answer.user = current_user

    if @answer.save
      flash[:notice] = "Thanks!"
      redirect_to question_path(@question)
    else
      flash[:notice] = "Something went wrong adding your answer"
      redirect_to question_path(@question)
    end
  end
end
