class Admin::ModerateController < ApplicationController
  before_filter :login_required
  before_filter :moderator_required

  def index
    @active_subtab = params.fetch(:tab, "questions")

    @banned = !!params[:banned]

    options = {:order => "flags_count desc",
               :flags_count.gt => 0,
               :banned => @banned,
               :group_id => current_group.id}

    banned = {:order => "flags_count desc",
               :flags_count.gt => 0,
               :banned => true,
               :group_id => current_group.id}

    case @active_subtab
      when "questions"
        @questions = Question.paginate(options.merge({:per_page => params[:per_page] || 25,
                                       :page => params[:questions_page] || 1}))
      when "answers"
        @answers = Answer.paginate(options.merge({:per_page => params[:per_page] || 25,
                                       :page => params[:answers_page] || 1}))
      when "banned"
        @banned = Question.paginate(banned.merge({:per_page => params[:per_page] || 25,
                                       :page => params[:questions_page] || 1}))
    end
  end

  def ban
    Question.ban(params[:question_ids] || [])
    Answer.ban(params[:answer_ids] || [])

    respond_to do |format|
      format.html{redirect_to :action => "index"}
    end
  end

  def unban
    Question.unban(params[:question_ids] || [])

    respond_to do |format|
      format.html{redirect_to :action => "index"}
    end
  end

end

