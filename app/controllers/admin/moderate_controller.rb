class Admin::ModerateController < ApplicationController
  before_filter :authenticate_user!
  before_filter :moderator_required

  def index
    @active_subtab = params.fetch(:tab, "questions")

    options = {:order => "flags_count desc",
               :flags_count.gt => 0,
               :banned => false,
               :group_id => current_group.id}

    case @active_subtab
      when "questions"
        @questions = Question.paginate(options.merge({:per_page => params[:per_page] || 25,
                                       :page => params[:questions_page] || 1}))
      when "answers"
        @answers = Answer.paginate(options.merge({:per_page => params[:per_page] || 25,
                                       :page => params[:answers_page] || 1}))
    end
  end

  def ban
    Question.ban(params[:question_ids] || [])
    Answer.ban(params[:answer_ids] || [])

    respond_to do |format|
      format.html{redirect_to :action => "index"}
    end
  end

end

